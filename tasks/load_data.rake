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
    j.regions
  end

  desc 'Load S3 Buckets'
  task :buckets do
    puts 'loading buckets'
    j = NeoInfra::Aws.new
    j.buckets
  end

  desc 'Load Nodes'
  task :nodes do
    puts 'loading nodes'
    j = NeoInfra::Nodes.new
    j.nodes
  end

  desc 'Load Everything'
  task all: %i[accounts regions vpcs buckets nodes]

end
