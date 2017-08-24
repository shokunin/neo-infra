# frozen_string_literal: true

require 'nodes'
require 'accounts'
require 'fog'
require 'neo4j'
require 'neoinfra/aws'

# NeoInfra Account information
module NeoInfra
  # Provide informations about the accounts available
  class Nodes
    def load_nodes
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
          region_conf = { region: region }
          new_conn = Fog::Compute.new(region_conf.merge(base_conf))
          new_conn.servers.all.each do |ec2|
            if SshKey.where(name: ec2.key_name).empty?
              s = SshKey.new(
                name: ec2.key_name,
                account: account[:name]
              )
              s.save
              SshKeyAccount.create(from_node: s, to_node: AwsAccount.where(name: account[:name]).first)
            end

            next unless Node.where(node_id: ec2.id).empty?
            node_name = if ec2.tags.empty?
                          ec2.id
                        elsif ec2.tags.key? 'Name'
                          ec2.tags['Name']
                        else
                          ec2.id
                        end
            n = Node.new(
              name: node_name,
              node_id: ec2.id,
              ip: ec2.private_ip_address,
              public_ip: ec2.public_ip_address,
              size: ec2.flavor_id,
              state: ec2.state,
              ami: ec2.image_id
            )
            n.save
            NodeAccount.create(from_node: n, to_node: AwsAccount.where(name: account[:name]).first)
            NodeSubnet.create(from_node: n, to_node: Subnet.where(subnet_id: ec2.subnet_id).first)
            NodeAz.create(from_node: n, to_node: Az.where(az: ec2.availability_zone).first)
            NodeSshKey.create(from_node: n, to_node: SshKey.where(name: ec2.key_name).first)
          end
        end
      end
    end
  end
end
