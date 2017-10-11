# frozen_string_literal: true

require 'neoinfra'
require 'vpc'
require 'accounts'
require 'fog-aws'
require 'neo4j'

# NeoInfra Account information
module NeoInfra
  # Provide informations about the accounts available
  class Vpcs

    def initialize
      @cfg = NeoInfra::Config.new
      neo4j_url = "http://#{@cfg.neo4j[:host]}:#{@cfg.neo4j[:port]}"
      Neo4j::Session.open(:server_db, neo4j_url)
    end

    def non_default_vpc_count
      p Vpc.all
      21
    end

    def default_vpc_count
      22
    end

    def list_vpcs
      node_counts = Hash.new(0)
      Node.all.each{|x| node_counts[x.subnet.subnet.name]+=1}
      Vpc.all.collect{|x| {'nodes' => node_counts[x.name], 'vpc_id' => x.vpc_id, 'name'=>x.name, 'region' => x.region.region, 'owner' => x.owned.name, 'cidr' => x.cidr, 'default' => x.default} }.select{ |y| y['default'] == "false"}.sort_by{|h| h['nodes']}.reverse
    end

    def load
      aws = NeoInfra::Aws.new
      @cfg.accounts.each do |account|
        base_conf = {
          provider: 'AWS',
          aws_access_key_id: account[:key],
          aws_secret_access_key: account[:secret]
        }
        aws.regions.each do |region|
          region_conf = { region: region }
          new_conn = Fog::Compute.new(region_conf.merge(base_conf))
          # Get VPCs
          new_conn.vpcs.all.each do |vpc|
            next unless Vpc.where(vpc_id: vpc.id).empty?
            vpc_name = if vpc.tags.empty?
                         vpc.id
                       elsif vpc.tags.key? 'Name'
                         vpc.tags['Name']
                       else
                         vpc.id
                       end
            vpc_id = Vpc.new(
              vpc_id: vpc.id,
              name: vpc_name,
              cidr: vpc.cidr_block,
              state: vpc.state,
              default: vpc.is_default.to_s
            )
            vpc_id.save
            AccountVpc.create(from_node: vpc_id, to_node: AwsAccount.where(name: account[:name]).first)
            VpcRegion.create(from_node: vpc_id, to_node: Region.where(region: region).first)
          end
          # Get all Subnets
          new_conn.subnets.all.each do |subnet|
            next unless Subnet.where(subnet_id: subnet.subnet_id).empty?
            subnet_name = if subnet.tag_set.empty?
                            subnet.subnet_id
                          elsif subnet.tag_set.key? 'Name'
                            subnet.tag_set['Name']
                          else
                            subnet.subnet_id
                          end
            sn = Subnet.new(
              subnet_id: subnet.subnet_id,
              cidr: subnet.cidr_block,
              name: subnet_name,
              ip_count: subnet.available_ip_address_count,
              state: subnet.state
            )
            sn.save
            VpcSubnet.create(from_node: sn, to_node: Vpc.where(vpc_id: subnet.vpc_id).first)
            begin
              SubnetAz.create(from_node: sn, to_node: Az.where(az: subnet.availability_zone).first)
            rescue
              #  Handle the case of hanging subnets
              puts "Account #{account[:name]} couldn't load the following subnet:"
              p subnet
            end
          end
        end
      end
    end
  end
end
