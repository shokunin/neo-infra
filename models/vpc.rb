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

# Provide the subnet information
class Subnet
  include Neo4j::ActiveNode
  property :subnet_id, constraint: :unique
  property :name
  property :cidr
  property :ip_count
  property :state
  has_one :out, :az, rel_class: :SubnetAz
  has_one :out, :subnet, rel_class: :VpcSubnet
end

###############################################################################
# Relationships go below here
###############################################################################
# Provide Neo4J Model for VPC Owners
class AccountVpc
  include Neo4j::ActiveRel
  from_class :Vpc
  to_class :AwsAccount
  type :owned
end

# Relationship between Subnet and VPC
class VpcSubnet
  include Neo4j::ActiveRel
  from_class :Subnet
  to_class :Vpc
  type :subnet
end

# Relationship between the VPC and the Region
class VpcRegion
  include Neo4j::ActiveRel
  from_class :Vpc
  to_class :Region
  type :region
end

# Relationship between the Subnet and the AZ
class SubnetAz
  include Neo4j::ActiveRel
  from_class :Subnet
  to_class :Az
  type :az
end
