# frozen_string_literal: true

require 'accounts'
require 'regions'
require 'mime-types'
require 'fog-aws'
require 's3'
require 'neo4j'
require 'neoinfra/config'
require 'neoinfra/cloudwatch'

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

    def region_count
      Region.all.length
    end

    def az_count
      Az.all.length
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

    def load_buckets
      @cfg = NeoInfra::Config.new
      cw = NeoInfra::Cloudwatch.new
      neo4j_url = "http://#{@cfg.neo4j[:host]}:#{@cfg.neo4j[:port]}"
      Neo4j::Session.open(:server_db, neo4j_url)
      @cfg.accounts.each do |account|
        base_conf = {
          provider: 'AWS',
          aws_access_key_id: account[:key],
          aws_secret_access_key: account[:secret]
        }
        s = Fog::Storage.new(base_conf)
        s.directories.each do |bucket|
          next unless Bucket.where(name: bucket.key).empty?
          b = Bucket.new(
            name: bucket.key,
            size: cw.get_bucket_size(account[:key], account[:secret], bucket.location, bucket.key)
          )
          b.save
          BucketRegion.create(from_node: b, to_node: Region.where(region: bucket.location).first)
          BucketAccount.create(from_node: b, to_node: AwsAccount.where(name: account[:name]).first)
        end
      end
    end
  end
end
