# frozen_string_literal: true

require 'neo4j'

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
end

class SshKey
  include Neo4j::ActiveNode
  property :name
  property :account
end

class NodeSubnet
  include Neo4j::ActiveRel
  from_class :Node
  to_class :Subnet
  type :subnet
end

class NodeAz
  include Neo4j::ActiveRel
  from_class :Node
  to_class :Az
  type :az
end

class NodeSshKey
  include Neo4j::ActiveRel
  from_class :Node
  to_class :SshKey
  type :sshkey
end

class NodeAccount
  include Neo4j::ActiveRel
  from_class :Node
  to_class :AwsAccount
  type :owner
end

class SshKeyAccount
  include Neo4j::ActiveRel
  from_class :SshKey
  to_class :AwsAccount
  type :owner
end
