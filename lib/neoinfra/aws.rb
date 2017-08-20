# frozen_string_literal: true

require 'accounts'
require 'fog'
require 'neoinfra/config'

# NeoInfra Account information
module NeoInfra
  # Provide informations about the accounts available
  class Aws
    def regions

      @cfg = NeoInfra::Config.new
      account = @cfg.accounts.first
      base_conf = {
        :provider              => 'AWS',
        :aws_access_key_id     => account[:key],
        :aws_secret_access_key => account[:secret]
      }

      conn  = Fog::Compute.new(base_conf)
      conn.describe_regions.data[:body]['regionInfo'].collect{ |x| x['regionName']}

    end
  end
end
