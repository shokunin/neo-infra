# frozen_string_literal: true

require 'accounts'
require 'yaml'
require 'fog-aws'
require 'neo4j'
require 'neoinfra/config'

# NeoInfra Account information
module NeoInfra
  # Provide informations about the accounts available
  class Accounts
    def list_names
      @cfg = NeoInfra::Config.new
      @cfg.accounts.map { |x| x[:name] }
    end

    def load
      @cfg = NeoInfra::Config.new

      neo4j_url = "http://#{@cfg.neo4j[:host]}:#{@cfg.neo4j[:port]}"
      Neo4j::Session.open(:server_db, neo4j_url)

      @cfg.accounts.each do |account|
        base_conf = {
          aws_access_key_id: account[:key],
          aws_secret_access_key: account[:secret]
        }

        # Grab the current user id string
        iam = Fog::AWS::IAM.new(base_conf)

        next unless AwsAccount.where(name: account[:name]).empty?
        account = AwsAccount.new(
          name:       account[:name],
          account_id: iam.users.current.arn.split(':')[4],
          user_id:    iam.users.current.id,
          key_md5:    Digest:: MD5.hexdigest(account[:key]),
          secret_md5: Digest:: MD5.hexdigest(account[:secret])
        )
        account.save
      end
    end
  end
end
