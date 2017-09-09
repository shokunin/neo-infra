# frozen_string_literal: true

require 'yaml'

namespace :sample_data do

  sample_data = YAML.load_file(
    File.join(File.dirname(File.expand_path(__FILE__)), 'sample_data.yaml')
  )
  Neo4j::Session.open(:server_db, 'http://localhost:7474')
  
  task :accounts do
    puts 'loading accounts'
      sample_data['accounts'].each do |account| 
	next unless AwsAccount.where(name: account[:name]).empty?
	acct = AwsAccount.new(
	  name:       account[:name],
	  account_id: 90000+rand(20),
	  user_id:    account[:name],
	  key_md5:    Digest:: MD5.hexdigest(account[:name]),
	  secret_md5: Digest:: MD5.hexdigest(account[:name])
	)
	acct.save
      end
  end

  task :vpcs do
    puts 'loading vpcs'
    j = NeoInfra::Vpcs.new
  end

  task :regions do
    puts 'loading regions'
    j = NeoInfra::Aws.new
  end

  task :buckets do
    puts 'loading buckets'
    j = NeoInfra::Aws.new
  end

  task :nodes do
    puts 'loading nodes'
    #j = NeoInfra::Nodes.new
  end

  desc 'Load Sample Data'
  task all: %i[accounts regions vpcs buckets nodes]
end
