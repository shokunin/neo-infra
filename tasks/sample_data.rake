# frozen_string_literal: true

require 'yaml'
require 'pp'

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

  task :regions do
    puts 'loading regions'
    sample_data['regions'].each do |reg|
    	next unless Region.where(region: reg.keys.first).empty?
      r = Region.new(region: reg.keys.first)
      r.save
      reg[reg.keys.first].each do |az|
        a = Az.new(az: az)
        a.save
        AzRegion.create(from_node: a, to_node: Region.where(region: reg.keys.first).first)
      end
    end
  end

  task :vpcs do
    puts 'loading vpcs'
    sample_data['vpcs'].each do |v|
    	next unless Vpc.where(vpc_id: v['vpc_id']).empty?
      vp = Vpc.new(
        vpc_id: v['vpc_id'],
        name: v['name'],
        cidr: v['cidr'],
        state: v['state'],
        default: v['default'].to_s
      )
      vp.save
      AccountVpc.create(from_node: vp, to_node: AwsAccount.where(name: v['account']).first)
      VpcRegion.create(from_node: vp, to_node: Region.where(region: v['region']).first)
    end
  end

  task :subnets do
    puts 'loading subnets'
    sample_data['subnets'].each do |s|
    	next unless Subnet.where(subnet_id: s['subnet_id']).empty?
      sn = Subnet.new(
        subnet_id: s['subnet_id'],
        cidr: s['cidr'],
        name: s['name'],
        ip_count: s['ip_count'],
        state: s['state']
      )
      VpcSubnet.create(from_node: sn, to_node: Vpc.where(vpc_id: s['vpc_id']).first)
      SubnetAz.create(from_node: sn, to_node: Az.where(az: s['az']).first)
    end
  end

  task :buckets do
    puts 'loading buckets'
    j = NeoInfra::Aws.new
  end

  task :ssh_keys do
    puts 'loading ssh_keys'
    sample_data['ssh_keys'].each do |k|
    	next unless SshKey.where(name: k['name']).empty?
      s = SshKey.new(
        name: k['name'],
        account: k['account'],
      )
      s.save
      SshKeyAccount.create(from_node: s, to_node: AwsAccount.where(name: k['account']).first)
    end

  end

  task :nodes do
    puts 'loading nodes'
    sample_data['nodes'].each do |n|
    	next unless Node.where(node_id: n['node_id']).empty?
      node = Node.new(
        node_id: n['node_id'],
        name:  n['name'],
        ip:  n['ip'],
        public_ip: n['public_ip'],
        size: n['size'],
        state: 'running',
        ami: n['ami'],
      )
      node.save
      NodeAccount.create(from_node: node, to_node: AwsAccount.where(name: n['account']).first)
      NodeSubnet.create(from_node: node, to_node: Subnet.where(subnet_id: n['subnet_id']).first)
      NodeAz.create(from_node: node, to_node: Az.where(az: n['az']).first)
      NodeSshKey.create(from_node: node, to_node: SshKey.where(name: n['ssh_key']).first)
    end
  end

  desc 'Load Sample Data'
  task all: %i[accounts regions vpcs subnets ssh_keys buckets nodes]
end
