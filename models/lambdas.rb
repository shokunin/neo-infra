# frozen_string_literal: true

require 'neo4j'

# Information on Lambda
class Lambda
  include Neo4j::ActiveNode
  property :name
  property :runtime
  property :lambda_timeout
  property :handler
  property :memorysize
  property :arn
  property :codesize
  property :last_modified
  has_one :out, :region, rel_class: :LambdaRegion
  has_one :out, :owner, rel_class: :LambdaAccount
end

# Map Lambda to Region
class LambdaRegion
  include Neo4j::ActiveRel
  from_class :Lambda
  to_class :Region
  type :region
end

# Map Lambda to Region
class LambdaAccount
  include Neo4j::ActiveRel
  from_class :Lambda
  to_class :AwsAccount
  type :owner
end
