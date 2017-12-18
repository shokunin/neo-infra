# frozen_string_literal: true

require 'accounts'
require 'regions'
require 'mime-types'
require 'fog-aws'
require 's3'
require 'ipaddr'
require 'neo4j'
require 'rds'
require 'neoinfra/config'
require 'neoinfra/cloudwatch'

RFC_1918 = [
  IPAddr.new('10.0.0.0/8'),
  IPAddr.new('172.16.0.0/12'),
  IPAddr.new('192.168.0.0/16'),
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
      account = @cfg.accounts.first
      base_conf = {
        provider: 'AWS',
        aws_access_key_id: account[:key],
        aws_secret_access_key: account[:secret],
        region: region
      }
      conn = Fog::Compute.new(base_conf)
      conn.describe_availability_zones.data[:body]['availabilityZoneInfo'].collect { |x| x['zoneName'] }
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
        buckets <<  {
          'name'       => b.name,
          'size'       => b.size,
          'versioning' => b.versioning,
          'creation'   => b.creation,
          'region'     => b.region.region,
          'owner'      => b.owner.name
        }
      end
      return buckets
    end

    def load_buckets
      cw = NeoInfra::Cloudwatch.new
      @cfg.accounts.each do |account|
        base_conf = {
          provider: 'AWS',
          aws_access_key_id: account[:key],
          aws_secret_access_key: account[:secret]
        }
        s = Fog::Storage.new(base_conf)
        s.directories.each do |bucket|
          next unless Bucket.where(name: bucket.key).empty?
          begin
            vers = bucket.versioning?.to_s
            crea =  bucket.creation_date.to_s
          rescue
            vers = "unknown"
            crea = "unknown"
          end
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

    def load_security_groups
      @cfg.accounts.each do |account|
        base_conf = {
          provider: 'AWS',
          aws_access_key_id: account[:key],
          aws_secret_access_key: account[:secret]
        }
        self.regions.each do |region|
          region_conf = { region: region }
          conn = Fog::Compute.new(region_conf.merge(base_conf))
          conn.security_groups.all.each do |grp|
            if SecurityGroup.where(sg_id: grp.group_id).empty?
              g = SecurityGroup.new(
                sg_id: grp.group_id,
                name: grp.name,
                description: grp.description,
              )
              g.save
              SecurityGroupOwner.create(from_node: g, to_node:  AwsAccount.where(account_id: grp.owner_id).first)
              SecurityGroupVpc.create(from_node: g, to_node:  Vpc.where(vpc_id: grp.vpc_id).first)
            end
            grp.ip_permissions.each do |iprule|
                  if iprule['ipProtocol'] != "-1"
                  iprule['ipRanges'].each do |r|
                    if iprule['toPort'] == -1
                      to_port = 65535
                    else
                      to_port = iprule['toPort']
                    end
                    if iprule['fromPort'] == -1
                      from_port = 0
                    else
                      from_port = iprule['fromPort']
                    end
                    if IpRules.where(
                      cidr_block: r['cidrIp'],
                      direction: 'ingress',
                      proto: iprule['ipProtocol'],
                      to_port: to_port,
                      from_port: from_port,
                    ).empty?
                      rl = IpRules.new(
                        cidr_block: r['cidrIp'],
                        direction: 'ingress',
                        proto: iprule['ipProtocol'],
                        to_port: to_port,
                        from_port: from_port,
                        private: RFC_1918.any? { |rfc| rfc.include?(IPAddr.new(r['cidrIp']))}
                      )
                      rl.save
                    end
                  end
                end
              end
              #
          end
        end
      end
    end

    def load_rds
      @cfg.accounts.each do |account|
        base_conf = {
          aws_access_key_id: account[:key],
          aws_secret_access_key: account[:secret]
        }
        s = Fog::AWS::RDS.new(base_conf)
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
            allocated_storage: rds.allocated_storage,
          )
          r.save
          RdsAz.create(from_node: r, to_node: Az.where(az: rds.availability_zone).first)
          RdsAccount.create(from_node: r, to_node: AwsAccount.where(name: account[:name]).first)
        end
      end
    end
  end
end
