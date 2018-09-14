# frozen_string_literal: true

require 'accounts'
require 'regions'
require 'mime-types'
require 'fog-aws'
require 's3'
require 'date'
require 'ipaddr'
require 'neo4j'
require 'rds'
require 'lambdas'
require 'neoinfra/config'
require 'neoinfra/cloudwatch'

RFC_1918 = [
  IPAddr.new('10.0.0.0/8'),
  IPAddr.new('172.16.0.0/12'),
  IPAddr.new('192.168.0.0/16')
].freeze

# NeoInfra Account information
module NeoInfra
  # Provide informations about the accounts available
  class Aws
    def initialize
      @cfg = NeoInfra::Config.new
      neo4j_url = "http://#{@cfg.neo4j[:host]}:#{@cfg.neo4j[:port]}"
      Neo4j::Session.open(:server_db, neo4j_url)
    end

    def regions
      account = @cfg.accounts.first
      base_conf = {
        provider: 'AWS',
        aws_access_key_id: account[:key],
        aws_secret_access_key: account[:secret]
      }
      conn = Fog::Compute.new(base_conf)
      conn.describe_regions.data[:body]['regionInfo'].collect { |x| x['regionName'] }
    end

    def region_count
      Region.all.length
    end

    def az_count
      Az.all.length
    end

    def azs(region)
      azs = []
      @cfg.accounts.each do |account|
        base_conf = {
          provider: 'AWS',
          aws_access_key_id: account[:key],
          aws_secret_access_key: account[:secret],
          region: region
        }
        begin
          conn = Fog::Compute.new(base_conf)
          conn.describe_availability_zones.data[:body]['availabilityZoneInfo'].collect { |x| x['zoneName'] }.each do |z|
            azs << z
          end
        rescue Exception => e
          puts "Zone couldn't load region #{region}: #{e.message}"
        end
      end
      azs.uniq
    end

    def load_regions
      regions.each do |region|
        next unless Region.where(region: region).empty?
        r = Region.new(
          region: region
        )
        r.save
        azs(region).each do |az|
          next unless Az.where(az: az).empty?
          a = Az.new(az: az)
          a.save
          AzRegion.create(from_node: a, to_node: Region.where(region: region).first)
        end
      end
    end

    def list_buckets
      buckets = []
      Bucket.all.order('n.size DESC').each do |b|
        buckets << {
          'name'       => b.name,
          'size'       => b.size,
          'versioning' => b.versioning,
          'creation'   => b.creation,
          'region'     => b.region.region,
          'owner'      => b.owner.name
        }
      end
      buckets
    end

    def load_buckets
      aws = NeoInfra::Aws.new
      cw = NeoInfra::Cloudwatch.new
      @cfg.accounts.each do |account|
        base_conf = {
          provider: 'AWS',
          aws_access_key_id: account[:key],
          aws_secret_access_key: account[:secret]
        }
        aws.regions.each do |region|
          region_conf = { region: region }
          s = Fog::Storage.new(region_conf.merge(base_conf))
          s.directories.each do |bucket|
            next unless bucket.location == region
            next unless Bucket.where(name: bucket.key).empty?
            vers = bucket.versioning?.to_s
            crea = bucket.creation_date.to_s
            b = Bucket.new(
              name: bucket.key,
              versioning: vers,
              creation: crea,
              size: cw.get_bucket_size(account[:key], account[:secret], bucket.location, bucket.key)
            )
            b.save
            BucketRegion.create(from_node: b, to_node: Region.where(region: bucket.location).first)
            BucketAccount.create(from_node: b, to_node: AwsAccount.where(name: account[:name]).first)
          end
        end
      end
    end

    def load_security_groups
      @cfg.accounts.each do |account|
        base_conf = {
          provider: 'AWS',
          aws_access_key_id: account[:key],
          aws_secret_access_key: account[:secret]
        }
        regions.each do |region|
          region_conf = { region: region }
          begin
            conn = Fog::Compute.new(region_conf.merge(base_conf))
          rescue StandardError
            puts "Error loading security groups for region #{region}"
            next
          end
          conn.security_groups.all.each do |grp|
            if SecurityGroup.where(sg_id: grp.group_id).empty?
              g = SecurityGroup.new(
                sg_id: grp.group_id,
                name: grp.name,
                description: grp.description
              )
              g.save
              begin
                SecurityGroupOwner.create(from_node: g, to_node: AwsAccount.where(account_id: grp.owner_id).first)
                unless grp.vpc_id.nil?
                  SecurityGroupVpc.create(from_node: g, to_node: Vpc.where(vpc_id: grp.vpc_id).first)
                end
              rescue
                puts "Account #{account[:name]} couldn't load the following security group:"
                p grp
              end
            end
            grp.ip_permissions.each do |iprule|
              next unless iprule['ipProtocol'] != '-1'
              iprule['ipRanges'].each do |r|
                to_port = if iprule['toPort'] == -1
                            65_535
                          else
                            iprule['toPort']
                          end
                from_port = if iprule['fromPort'] == -1
                              0
                            else
                              iprule['fromPort']
                            end
                if IpRules.where(
                  cidr_block: r['cidrIp'],
                  direction: 'ingress',
                  proto: iprule['ipProtocol'],
                  to_port: to_port,
                  from_port: from_port
                ).empty?
                  rl = IpRules.new(
                    cidr_block: r['cidrIp'],
                    direction: 'ingress',
                    proto: iprule['ipProtocol'],
                    to_port: to_port,
                    from_port: from_port,
                    private: RFC_1918.any? { |rfc| rfc.include?(IPAddr.new(r['cidrIp'])) }
                  )
                  rl.save
                end
                # TODO: remove duplicate Relationships
                SecurityGroupsIpRules.create(
                  from_node: SecurityGroup.where(sg_id: grp.group_id).first,
                  to_node: IpRules.where(
                    cidr_block: r['cidrIp'],
                    direction: 'ingress',
                    proto: iprule['ipProtocol'],
                    to_port: to_port,
                    from_port: from_port,
                    private: RFC_1918.any? { |rfc| rfc.include?(IPAddr.new(r['cidrIp'])) }
                  ).first
                )
              end
            end
          end
        end
      end
    end

    def list_lambdas
      lambdas = []
      Lambda.all.each do |l|
        lambdas << {
          'name'           => l.name,
          'runtime'        => l.runtime,
          'handler'        => l.handler,
          'lambda_timeout' => l.lambda_timeout,
          'memorysize'     => l.memorysize,
          'last_modified'  => l.last_modified,
          'region'         => l.region.region,
          'owner'          => l.owner.name
        }
      end
      lambdas
    end

    def list_rds
      rds = []
      Rds.all.each do |r|
        rds << {
          'name'              => r.name,
          'size'              => r.size,
          'engine'            => r.engine,
          'engine_version'    => r.engine_version,
          'multi_az'          => r.multi_az,
          'endpoint'          => r.endpoint,
          'port'              => r.port,
          'allocated_storage' => r.allocated_storage,
          'owner'             => r.owner.name,
          'az'                => r.az.az,
        }
      end
      rds
    end

    def load_lambda
      @cfg.accounts.each do |account|
        base_conf = {
          aws_access_key_id: account[:key],
          aws_secret_access_key: account[:secret]
        }
        regions.each do |region|
          region_conf = { region: region }
          begin
            lambdas = Fog::AWS::Lambda.new(region_conf.merge(base_conf))
            lambdas.list_functions.data[:body]['Functions'].each do |f|
              next unless Lambda.where(name: f['FunctionArn']).empty?
              l = Lambda.new(
                name:             f['FunctionName'],
                runtime:          f['Runtime'],
                lambda_timeout:   f['Timeout'],
                handler:          f['Handler'],
                memorysize:       f['MemorySize'],
                arn:              f['FunctionArn'],
                codesize:         f['CodeSize'],
                last_modified:    f['LastModified']
              )
              l.save
              LambdaAccount.create(from_node: l, to_node: AwsAccount.where(name: account[:name]).first)
              LambdaRegion.create(from_node: l, to_node: Region.where(region: region).first)
            end
          rescue Exception => e
            puts "Error with #{region}: #{e.message}"
            next
          end
        end
      end
    end

    def list_dynamos
      dynamos = []
      Dynamo.all.order('n.sizebytes DESC').each do |d|
        dynamos << {
          'name'       => d.name,
          'size'       => d.sizebytes,
          'itemcount'  => d.itemcount,
          'status'     => d.status,
          'creation'   => d.creation,
          'region'     => d.region.region,
          'owner'      => d.owner.name
        }
      end
      dynamos
    end

    def load_dynamo
      @cfg.accounts.each do |account|
        base_conf = {
          aws_access_key_id: account[:key],
          aws_secret_access_key: account[:secret]
        }
        regions.each do |region|
          region_conf = { region: region }
          begin
            dyns = Fog::AWS::DynamoDB.new(region_conf.merge(base_conf))
            dyns.list_tables.data[:body]['TableNames'].each do |table|
              tb = dyns.describe_table(table).data[:body]['Table']
              next unless Dynamo.where(name: table['TableId']).empty?
              d = Dynamo.new(
                tableid:   tb['TableId'],
                name:   tb['TableName'],
                creation: Time.at(tb['CreationDateTime']).to_datetime.strftime('%F %H:%M:%S %Z'),
                arn:     tb['TableArn'],
                itemcount:   tb['ItemCount'],
                sizebytes:   tb['TableSizeBytes'],
                status:   tb['TableStatus'],
                readcap:   tb['ProvisionedThroughput']['ReadCapacityUnits'],
                writecap:   tb['ProvisionedThroughput']['WriteCapacityUnits'],
                capdecreases: tb['ProvisionedThroughput']['NumberOfDecreasesToday']
              )
              d.save
              DynamoAccount.create(from_node: d, to_node: AwsAccount.where(name: account[:name]).first)
              DynamoRegion.create(from_node: d, to_node: Region.where(region: region).first)
            end
          rescue Exception => e
            puts "Could not list Dynamos for region: #{region}: #{e.message}"
            next
          end
        end
        # dyns.list_tables.each do |table|
        #  p table
        # end
      end
    end

    def load_rds
      @cfg.accounts.each do |account|
        base_conf = {
          aws_access_key_id: account[:key],
          aws_secret_access_key: account[:secret]
        }
        regions.each do |region|
          region_conf = { region: region }
          s = Fog::AWS::RDS.new(region_conf.merge(base_conf))
          s.servers.each do |rds|
            next unless Rds.where(name: rds.id).empty?
            r = Rds.new(
              name: rds.id,
              size: rds.flavor_id,
              engine: rds.engine,
              engine_version: rds.engine_version,
              multi_az: rds.multi_az.to_s,
              endpoint: rds.endpoint['Address'],
              port: rds.endpoint['Port'],
              allocated_storage: rds.allocated_storage
            )
            r.save
            begin
              RdsAz.create(from_node: r, to_node: Az.where(az: rds.availability_zone).first)
              RdsAccount.create(from_node: r, to_node: AwsAccount.where(name: account[:name]).first)
            rescue Exception => e
              puts "Account #{account[:name]} couldn't load the following rds: #{e.message}"
              p r
              next
            end
          end
        end
      end
    end
  end
end
