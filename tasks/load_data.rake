# frozen_string_literal: true

namespace :load_data do
  desc 'Load accounts into the neo4j container'
  task :accounts do
    puts 'loading accounts'
    j = NeoInfra::Accounts.new
    j.load
  end

  desc 'Load VPCs into the neo4j container'
  task :vpcs do
    puts 'loading vpcs'
    j = NeoInfra::Vpcs.new
    j.load
  end

  desc 'Load Region and Availability Zone information'
  task :regions do
    puts 'loading regions'
    j = NeoInfra::Aws.new
    j.load_regions
  end

  desc 'Load S3 Buckets'
  task :buckets do
    puts 'loading buckets'
    j = NeoInfra::Aws.new
    j.load_buckets
  end

  desc 'Load Nodes'
  task :nodes do
    puts 'loading nodes'
    j = NeoInfra::Nodes.new
    j.load_nodes
  end

  desc 'Load RDS'
  task :rds do
    puts 'loading rds'
    j = NeoInfra::Aws.new
    j.load_rds
  end

  desc 'Load Security Groups'
  task :security_groups do
    puts 'loading Security Groups'
    j = NeoInfra::Aws.new
    j.load_security_groups
  end

  desc 'Load Dynamo'
  task :dynamo do
    puts 'loading Dynamo'
    j = NeoInfra::Aws.new
    j.load_dynamo
  end

  desc 'Load Lambdas'
  task :lambda do
    puts 'loading Lambdas'
    j = NeoInfra::Aws.new
    j.load_lambda
  end

  desc 'Load Everything'
  task all: %i[accounts regions vpcs buckets security_groups nodes rds dynamo lambda]
end
