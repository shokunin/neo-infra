# frozen_string_literal: true

require 'neo4j'

# Node setup
class Node
  include Neo4j::ActiveNode
  property :node_id, constraint: :unique
  property :name
  property :ip
  property :public_ip
  property :size
  property :state
  property :ami
  has_one :out, :subnet, rel_class: :NodeSubnet
  has_one :out, :az, rel_class: :NodeAz
  has_one :out, :sshkey, rel_class: :NodeSshKey
  has_one :out, :account, rel_class: :NodeAccount
  has_many :out, :node_sg, rel_class: :NodeSecurityGroup
end

class SecurityGroup
  include Neo4j::ActiveNode
  property :sg_id, constraint: :unique
  property :name
  property :description
  has_one  :out, :sg_owner, rel_class: :SecurityGroupOwner
  has_one  :out, :sg_vpc, rel_class: :SecurityGroupVpc
#  has_many :out, :ip_rules, rel_class: :SecurityGroupsIpRules
#  has_many :out, :sg_rules, rel_class: :SecurityGroupsSgRules
end

class NodeSecurityGroup
  include Neo4j::ActiveRel
  from_class :Node
  to_class   :SecurityGroup
  type       :node_sg
end

class SecurityGroupOwner
  include Neo4j::ActiveRel
  from_class :SecurityGroup
  to_class   :AwsAccount
  type       :sg_owner
end

class SecurityGroupVpc
  include Neo4j::ActiveRel
  from_class :SecurityGroup
  to_class   :Vpc
  type       :sg_vpc
end

class IpRules
  include Neo4j::ActiveNode
  property :cidr_block
  property :direction
  property :proto
  property :start_port
end

# SSH key class
class SshKey
  include Neo4j::ActiveNode
  property :name
  property :account
end

# Relationship with subnet
class NodeSubnet
  include Neo4j::ActiveRel
  from_class :Node
  to_class :Subnet
  type :subnet
end

# Relationship with az
class NodeAz
  include Neo4j::ActiveRel
  from_class :Node
  to_class :Az
  type :az
end

# Relationship with key
class NodeSshKey
  include Neo4j::ActiveRel
  from_class :Node
  to_class :SshKey
  type :sshkey
end

# Relationship with account
class NodeAccount
  include Neo4j::ActiveRel
  from_class :Node
  to_class :AwsAccount
  type :owner
end

# Relationship with account
class SshKeyAccount
  include Neo4j::ActiveRel
  from_class :SshKey
  to_class :AwsAccount
  type :owner
end
