# frozen_string_literal: true

namespace :audit do
  task :audit_nodes do
    puts 'auditing Nodes'
    j = NeoInfra::Audit.new
    pp j.audit_nodes
  end

  desc 'Tag Audit'
  task all: %i[audit_nodes]
end
