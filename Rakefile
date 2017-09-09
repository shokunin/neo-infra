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

Dir.glob('tasks/*.rake').each { |r| import r }

RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = ['--display-cop-names']
end

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = Dir.glob('spec/*_spec.rb')
  t.rspec_opts = '--format documentation'
end
