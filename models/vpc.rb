# frozen_string_literal: true

require 'neo4j'

# Provide Neo4J Model for VPCs
class Vpc
  include Neo4j::ActiveNode
  property :vpc_id, constraint: :unique
  property :name
  property :cidr
  property :default
  property :state
  has_one :out, :region, rel_class: :VpcRegion
  has_one :out, :owned, rel_class: :AccountVpc
  has_many :out, :az, rel_class: :VpcAz
end

# Provide Neo4J Model for VPC Owners
class AccountVpc
  include Neo4j::ActiveRel
  from_class :Vpc
  to_class :AwsAccount
  type :owned
end
