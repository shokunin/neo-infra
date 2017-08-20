# frozen_string_literal: true

require 'vpc'
require 'accounts'
require 'fog'
require 'neo4j'
require 'neoinfra/aws'
require 'neoinfra/config'

# NeoInfra Account information
module NeoInfra
  # Provide informations about the accounts available
  class Vpcs
    def load
      aws = NeoInfra::Aws.new
      @cfg = NeoInfra::Config.new

      neo4j_url = "http://#{@cfg.neo4j[:host]}:#{@cfg.neo4j[:port]}"
      Neo4j::Session.open(:server_db, neo4j_url)

      @cfg.accounts.each do |account|
        base_conf = {
          provider: 'AWS',
          aws_access_key_id: account[:key],
          aws_secret_access_key: account[:secret]
        }
        aws.regions.each do |region|
          region_conf = {:region => region['regionName'] }
          new_conn = Fog::Compute.new(region_conf.merge(base_conf))
          new_conn.vpcs.all.each do |vpc|
            if Vpc.where(vpc_id: vpc.id).length < 1
              if vpc.tags.empty?
                vpc_name = vpc.id
              else
                if vpc.tags.has_key? "Name"
                  vpc_name = vpc.tags['Name']
                else
                  vpc_name = vpc.id
                end
              end
              vpc_id = Vpc.new(:vpc_id => vpc.id, :name => vpc_name, :cidr => vpc.cidr_block)
              vpc_id.save
              AccountVpc.create(from_node: vpc_id, to_node: AwsAccount.where(name: account[:name]).first )
            end
          end
        end
      end
    end
  end
end
