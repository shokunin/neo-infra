# frozen_string_literal: true

require 'neoinfra'
require 'vpc'
require 'accounts'
require 'fog-aws'
require 'neo4j'
require 'csv'
require 'sinatra'
require 's3'


# NeoInfra Account information
module NeoInfra
  # Provide informations about the accounts available
  class Graph
    def initialize
      @cfg = NeoInfra::Config.new
      neo4j_url = "http://#{@cfg.neo4j[:host]}:#{@cfg.neo4j[:port]}"
      Neo4j::Session.open(:server_db, neo4j_url)
    end

    def graph_vpcs
      csv_string = CSV.generate(force_quotes: false ) do |csv|
        csv << ['id,value']
        csv << ['aws,']
        @cfg = NeoInfra::Config.new
        @cfg.accounts.each do |account|
          csv << ["aws.#{account[:name]},"]

          Vpc.where(default: "false").select{|x| x.owned.name == account[:name]}.collect{|y| y.region.region}.uniq.each do |region|
            csv << ["aws.#{account[:name]}.#{region},"]
          end

          Vpc.where(default: "false").each do |vpc|
            if vpc.owned.name == account[:name]
              csv << ["aws.#{account[:name]}.#{vpc.region.region}.#{vpc.name},1"]
            end
          end

        end
      end
      return csv_string.gsub('"', '')
    end
 
    def graph_buckets
      csv_string = CSV.generate(force_quotes: false ) do |csv|
        csv << ['id,value']
        csv << ['aws,']
        @cfg = NeoInfra::Config.new
        @cfg.accounts.each do |account|
          csv << ["aws.#{account[:name]},"]

          Bucket.all.select{|x| x.owner.name == account[:name]}.collect{|y| y.region.region}.uniq.each do |region|
            csv << ["aws.#{account[:name]}.#{region},"]
          end

          Bucket.all.each do |bucket|
            if bucket.owner.name == account[:name]
              csv << ["aws.#{account[:name]}.#{bucket.region.region}.#{bucket.name.gsub("\.", ':')},1"]
            end
          end

        end
      end
      return csv_string.gsub('"', '')
    end
  
    def graph_queues
      csv_string = CSV.generate(force_quotes: false ) do |csv|
        csv << ['id,value']
        csv << ['aws,']
        @cfg = NeoInfra::Config.new
        @cfg.accounts.each do |account|
          csv << ["aws.#{account[:name]},"]

          SQSQueue.all.select{|x| x.owner.name == account[:name]}.collect{|y| y.region.region}.uniq.each do |region|
            csv << ["aws.#{account[:name]}.#{region},"]
          end

          SQSQueue.all.each do |q|
            if q.owner.name == account[:name]
              csv << ["aws.#{account[:name]}.#{q.region.region}.#{q.name},1"]
            end
          end

        end
      end
      return csv_string.gsub('"', '')
    end 

  end
end
