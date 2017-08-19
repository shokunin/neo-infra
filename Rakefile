# frozen_string_literal: true

task default: :full_test

require 'rubocop/rake_task'

RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = ['--display-cop-names']
end

task full_test: [:rubocop]
