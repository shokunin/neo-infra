# frozen_string_literal: true

require 'neo4j'

# Information on Bucket
class Bucket
  include Neo4j::ActiveNode
  property :name, constraint: :unique
  property :size
  has_one :out, :region, rel_class: :BucketRegion
  has_one :out, :owner, rel_class: :BucketAccount
end

# Map Bucket to Region
class BucketRegion
  include Neo4j::ActiveRel
  from_class :Bucket
  to_class :Region
  type :region
end

# Map Bucket to Region
class BucketAccount
  include Neo4j::ActiveRel
  from_class :Bucket
  to_class :AwsAccount
  type :owner
end
