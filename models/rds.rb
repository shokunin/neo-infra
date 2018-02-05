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

class RdsAccount
  include Neo4j::ActiveRel
  from_class :Rds
  to_class :AwsAccount
  type :owner
end

class Dynamo
  include Neo4j::ActiveNode
  property :tableid, constraint: :unique
  property :name
  property :creation
  property :arn
  property :itemcount
  property :sizebytes
  property :status
  property :readcap
  property :writecap
  property :capdecreases
  has_one :out, :owner, rel_class: :DynamoAccount
  has_one :out, :region, rel_class: :DynamoRegion
end

class DynamoAccount
  include Neo4j::ActiveRel
  from_class :Dynamo
  to_class :AwsAccount
  type :owner
end

class DynamoRegion
  include Neo4j::ActiveRel
  from_class :Dynamo
  to_class :Region
  type :region
end

