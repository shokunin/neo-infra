# frozen_string_literal: true

require 'neoinfra'
require 'vpc'
require 'accounts'
require 'fog-aws'
require 'neo4j'

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
      nodes = []
      rels = []
      i = 0
      @cfg = NeoInfra::Config.new
      @cfg.accounts.each do |account|
        nodes << {title: account[:name], label: 'account'}
        i +=1
        Vpc.where(default: "false").each do |vpc|
          if vpc.owned.name == account[:name]
            source = i
            nodes << {title: vpc.name, label: 'vpc'}
            i +=1
            rels << {source: source, target: i}
          end
        end
      end
      return {nodes: nodes, links: rels}
    end
  end
end
