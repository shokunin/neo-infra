# frozen_string_literal: true

require 'neoinfra'
require 'vpc'
require 'accounts'
require 'fog-aws'
require 'neo4j'
require 'csv'
require 'sinatra'

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
          Vpc.where(default: "false").each do |vpc|
            if vpc.owned.name == account[:name]
              csv << ["aws.#{account[:name]}.#{vpc.name},1"]
            end
          end
        end
      end
      return csv_string.gsub('"', '')
    end

  end
end
