# frozen_string_literal: true

require 'neo4j'

# Information on Rds
class Rds
  include Neo4j::ActiveNode
  property :name, constraint: :unique
  property :size
  property :engine
  property :engine_version
  property :multi_az
  property :endpoint
  property :port
  property :allocated_storage
  has_one :out, :az, rel_class: :RdsAz
  has_one :out, :owner, rel_class: :RdsAccount
end

# Map Rds to Region
class RdsAz
  include Neo4j::ActiveRel
  from_class :Rds
  to_class :Az
  type :az
end

# Map Rds to Region
class RdsAccount
  include Neo4j::ActiveRel
  from_class :Rds
  to_class :AwsAccount
  type :owner
end
