# frozen_string_literal: true

# buckets frozen_string_literal: true

require 'neo4j'

# Information on Region
class Region
  include Neo4j::ActiveNode
  property :region, constraint: :unique
end

# Information on Availability Zones
class Az
  include Neo4j::ActiveNode
  property :az, constraint: :unique
  has_one :out, :region, rel_class: :AzRegion
end

# Map AZs to regions
class AzRegion
  include Neo4j::ActiveRel
  from_class :Az
  to_class :Region
  type :region
end
