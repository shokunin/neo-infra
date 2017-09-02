# frozen_string_literal: true

lib_dir = File.join(File.dirname(File.expand_path(__FILE__)), 'lib')
$LOAD_PATH.unshift(lib_dir) unless
  $LOAD_PATH.include?(lib_dir) || $LOAD_PATH.include?(lib_dir)

models_dir = File.join(File.dirname(File.expand_path(__FILE__)), 'models')
$LOAD_PATH.unshift(models_dir) unless
  $LOAD_PATH.include?(models_dir) || $LOAD_PATH.include?(models_dir)

task default: :full_test

require 'rubocop/rake_task'
require 'rake'
require 'pp'
require 'rspec/core/rake_task'
require 'neoinfra'

RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = ['--display-cop-names']
end

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = Dir.glob('spec/*_spec.rb')
  t.rspec_opts = '--format documentation'
end

desc 'Load accounts into the neo4j container'
task :load_accounts do
  puts 'loading accounts'
  j = NeoInfra::Accounts.new
  j.load
end

desc 'Load VPCs into the neo4j container'
task :load_vpcs do
  puts 'loading vpcs'
  j = NeoInfra::Vpcs.new
  j.load
end

desc 'Load Region and Availability Zone information'
task :load_regions do
  puts 'loading regions'
  j = NeoInfra::Aws.new
  j.load_regions
end

desc 'Load S3 Buckets'
task :load_buckets do
  puts 'loading buckets'
  j = NeoInfra::Aws.new
  j.load_buckets
end

desc 'Load Nodes'
task :load_nodes do
  puts 'loading nodes'
  j = NeoInfra::Nodes.new
  j.load_nodes
end

desc 'Load Everything'
task load_all: %i[load_accounts load_regions load_vpcs load_buckets load_nodes]
task full_test: %i[rubocop spec]

task :audit_nodes do
  puts 'auditing Nodes'
  j = NeoInfra::Audit.new
  pp j.audit_nodes
end

desc 'Tag Audit'
task audit_all: %i[audit_nodes]
