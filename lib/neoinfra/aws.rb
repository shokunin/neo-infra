# frozen_string_literal: true

require 'accounts'
require 'regions'
require 'fog'
require 'neo4j'
require 'neoinfra/config'

# NeoInfra Account information
module NeoInfra
  # Provide informations about the accounts available
  class Aws
    def regions
      @cfg = NeoInfra::Config.new
      account = @cfg.accounts.first
      base_conf = {
        provider: 'AWS',
        aws_access_key_id: account[:key],
        aws_secret_access_key: account[:secret]
      }
      conn = Fog::Compute.new(base_conf)
      conn.describe_regions.data[:body]['regionInfo'].collect { |x| x['regionName'] }
    end

    def azs(region)
      @cfg = NeoInfra::Config.new
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
      @cfg = NeoInfra::Config.new
      neo4j_url = "http://#{@cfg.neo4j[:host]}:#{@cfg.neo4j[:port]}"
      Neo4j::Session.open(:server_db, neo4j_url)
      self.regions.each do |region|
        next unless Region.where(region: region).empty?
        r = Region.new(
          region: region
        )
        r.save
        self.azs(region).each do |az|
          next unless Az.where(az: az).empty?
          a = Az.new(az: az)
          a.save
          AzRegion.create(from_node: a, to_node: Region.where(region: region).first )
        end
      end
    end

  end
end
