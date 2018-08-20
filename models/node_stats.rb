# frozen_string_literal: true

require 'neo4j'

# Node setup
class NodeStats
  include Neo4j::ActiveNode
  property :node_id, constraint: :unique
  property :cpu_max
  property :cpu_avg
  property :mem_max
  property :mem_avg
  has_one :out, :node, rel_class: :Node2Stats
end

class Node2Stats
  include Neo4j::ActiveRel
  from_class :Node
  to_class   :NodeStatus
  type       :node
end
