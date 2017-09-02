# frozen_string_literal: true

require 'nodes'
require 'accounts'
require 'fog'
require 'neoinfra/aws'

# NeoInfra Account information
module NeoInfra
  # Provide informations about the accounts available
  class Audit
    def audit_nodes
      results = Hash.new { |h, k| h[k] = {} }
      aws = NeoInfra::Aws.new
      @cfg = NeoInfra::Config.new

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
            %i[required recommended]. each do |a|
              next if (ec2.tags.keys.sort & @cfg.tag_policy[a].sort) == @cfg.tag_policy[a].sort
              results[ec2.id].merge!("#{a}_missing_tags" => @cfg.tag_policy[a].sort - ec2.tags.keys.sort,
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
  end
end
