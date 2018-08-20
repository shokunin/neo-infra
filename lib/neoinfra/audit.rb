# frozen_string_literal: true

require 'nodes'
require 'accounts'
require 'fog-aws'
require 'neoinfra'

# NeoInfra Account information
module NeoInfra
  # Provide informations about the accounts available
  class Audit
    def audit_nodes
      results = Hash.new { |h, k| h[k] = {} }
      aws = NeoInfra::Aws.new
      @cfg = NeoInfra::Config.new

      unless @cfg.tag_policy.has_key? :nodes
        puts "no policy set for nodes"
        return {:error => "No nodes tag policy"}
      end

      @cfg.accounts.each do |account|
        base_conf = {
          provider: 'AWS',
          aws_access_key_id: account[:key],
          aws_secret_access_key: account[:secret]
        }
        aws.regions.each do |region|
          region_conf = { region: region }
          # Get Instances
          new_conn = Fog::Compute.new(region_conf.merge(base_conf))
          new_conn.servers.all.each do |ec2|
            %i[required recommended].each do |a|
              next unless @cfg.tag_policy[:nodes].has_key? a
              next if (ec2.tags.keys.sort & @cfg.tag_policy[:nodes][a].sort) == @cfg.tag_policy[:nodes][a].sort
              results[ec2.id].merge!("#{a}_missing_tags" => @cfg.tag_policy[:nodes][a].sort - ec2.tags.keys.sort,
                                     'tags' => ec2.tags.keys.sort,
                                     'account' => account[:name],
                                     'launched' => ec2.created_at,
                                     'region' => region,
                                     'ssh_key' => ec2.key_name)
            end
          end
        end
      end
      results
    end

    def audit_vpcs
      results = Hash.new { |h, k| h[k] = {} }
      aws = NeoInfra::Aws.new
      @cfg = NeoInfra::Config.new

      unless @cfg.tag_policy.has_key? :vpcs
        puts "no policy set for vpcs"
        return {:error => "No vpc tag policy"}
      end

      @cfg.accounts.each do |account|
        base_conf = {
          provider: 'AWS',
          aws_access_key_id: account[:key],
          aws_secret_access_key: account[:secret]
        }
        aws.regions.each do |region|
          region_conf = { region: region }
          # Get Instances
          new_conn = Fog::Compute.new(region_conf.merge(base_conf))
          new_conn.vpcs.all.each do |vpc|
            %i[required recommended].each do |a|
              # we don't do default vpcs
              next if vpc.is_default
              next unless @cfg.tag_policy[:vpcs].has_key? a
              next if (vpc.tags.keys.sort & @cfg.tag_policy[:vpcs][a].sort) == @cfg.tag_policy[:vpcs][a].sort
              results[vpc.id].merge!("#{a}_missing_tags" => @cfg.tag_policy[:vpcs][a].sort - vpc.tags.keys.sort,
                                     'tags' => vpc.tags.keys.sort,
                                     'account' => account[:name],
                                     'region' => region)
            end
          end
        end
      end
      results
    end
 
    def audit_subnets
      results = Hash.new { |h, k| h[k] = {} }
      aws = NeoInfra::Aws.new
      @cfg = NeoInfra::Config.new

      unless @cfg.tag_policy.has_key? :subnets
        puts "no policy set for subnets"
        return {:error => "No subnet tag policy"}
      end

      @cfg.accounts.each do |account|
        base_conf = {
          provider: 'AWS',
          aws_access_key_id: account[:key],
          aws_secret_access_key: account[:secret]
        }
        aws.regions.each do |region|
          region_conf = { region: region }
          # Get Instances
          new_conn = Fog::Compute.new(region_conf.merge(base_conf))
          new_conn.subnets.all.each do |subnet|
            %i[required recommended].each do |a|
              next if subnet.default_for_az
              next unless @cfg.tag_policy[:subnets].has_key? a
              next if (subnet.tag_set.keys.sort & @cfg.tag_policy[:subnets][a].sort) == @cfg.tag_policy[:subnets][a].sort
              results[subnet.subnet_id].merge!("#{a}_missing_tags" => @cfg.tag_policy[:subnets][a].sort - subnet.tag_set.keys.sort,
                                     'tags' => subnet.tag_set.keys.sort,
                                     'account' => account[:name],
                                     'region' => region)
            end
          end
        end
      end
      results
    end

  end
end
