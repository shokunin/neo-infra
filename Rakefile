# frozen_string_literal: true

task default: :full_test

require 'rubocop/rake_task'
require 'rake'
require 'rspec/core/rake_task'

RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = ['--display-cop-names']
end

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = Dir.glob('spec/*_spec.rb')
  t.rspec_opts = '--format documentation'
end

task full_test: %i[rubocop spec]
