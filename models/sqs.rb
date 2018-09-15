# frozen_string_literal: true

require 'neo4j'

# Information on SQSQueue
class SQSQueue
  include Neo4j::ActiveNode
  property :url, constraint: :unique
  property :name
  property :modified
  property :creation
  property :retention
  property :maxsize
  has_one :out, :region, rel_class: :SQSQueueRegion
  has_one :out, :owner, rel_class: :SQSQueueAccount
end

# Map SQSQueue to Region
class SQSQueueRegion
  include Neo4j::ActiveRel
  from_class :SQSQueue
  to_class :Region
  type :region
end

# Map SQSQueue to Region
class SQSQueueAccount
  include Neo4j::ActiveRel
  from_class :SQSQueue
  to_class :AwsAccount
  type :owner
end
