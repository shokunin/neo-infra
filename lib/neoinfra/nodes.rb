# frozen_string_literal: true

require 'neo4j'
require 'neoinfra'
require 'nodes'
require 'accounts'
require 'fog-aws'

# NeoInfra Account information
module NeoInfra
  # Provide informations about the accounts available
  class Nodes
    def initialize
      @cfg = NeoInfra::Config.new
      neo4j_url = "http://#{@cfg.neo4j[:host]}:#{@cfg.neo4j[:port]}"
      Neo4j::Session.open(:server_db, neo4j_url)
    end

    def display_node(node_id)
      n = Node.where(node_id: node_id).first
      {
        'Name'          => n.name,
        'IP'            => n.ip,
        'State'         => n.state,
        'AMI'           => n.ami,
        'Public_IP'     => n.public_ip,
        'AZ'            => n.az.az,
        'Account'       => n.account.name,
        'Size'          => n.size,
        'Subnet'        => n.subnet.name,
        'VPC'           => n.subnet.subnet.name,
        'SSH-Key'       => n.sshkey.name,
        'SecurityGroup' => n.node_sg.name
      }
    end

    def search_nodes_by_name(name)
      results = {:nodes => [], :errors => []}
      if !Node.where(name: name).empty?
        Node.where(name: name).each do |k|
          results[:nodes] << display_node(k.node_id)
        end
      else
        results[:errors] << "Could not find a node with name: #{name}"
      end
      return results
    end

    def search_nodes_by_ip(ip)
      if !Node.where(ip: ip).empty?
        display_node(Node.where(ip: ip).first.node_id)
      else
        display_node(Node.where(public_ip: ip).first.node_id)
      end
    end

    def search_nodes_by_node_id(node_id)
      display_node(Node.where(node_id: node_id).first.node_id)
    end

    def load_nodes
      aws = NeoInfra::Aws.new

      @cfg.accounts.each do |account|
        base_conf = {
          provider: 'AWS',
          aws_access_key_id: account[:key],
          aws_secret_access_key: account[:secret]
        }
        aws.regions.each do |region|
          region_conf = { region: region }
          begin
            new_conn = Fog::Compute.new(region_conf.merge(base_conf))
          rescue StandardError
            puts "Error loading nodes in region: #{region}"
            next
          end
          new_conn.servers.all.each do |ec2|
            next if ec2.state == 'terminated'
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
            ec2.network_interfaces.reject(&:empty?).each do |i|
              next unless i.key? 'groupIds'
              i['groupIds'].each do |g|
                begin
                  NodeSecurityGroup.create(from_node: n, to_node: SecurityGroup.where(sg_id: g).first)
                rescue StandardError
                  puts "Security Groups: #{account[:name]}/#{region} couldn't get the following to work:"
                  p ec2
                  p g
                end
              end
            end
          end
        end
      end
    end
  end
end
