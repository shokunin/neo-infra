# frozen_string_literal: true

require 'neo4j'

# Provide Neo4J Model for aws accounts
class AwsAccount
  include Neo4j::ActiveNode
  property :name, constraint: :unique
  property :account_id, constraint: :unique
  # We get the md5 since so we can search if we only know the creds
  property :key_md5
  property :secret_md5
end
