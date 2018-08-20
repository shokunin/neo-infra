# frozen_string_literal: true

namespace :audit do
  task :audit_nodes do
    puts 'auditing Nodes'
    j = NeoInfra::Audit.new
    pp j.audit_nodes
  end

  task :audit_vpcs do
    puts 'auditing VPCs'
    j = NeoInfra::Audit.new
    pp j.audit_vpcs
  end

  task :audit_subnets do
    puts 'auditing Subnets'
    j = NeoInfra::Audit.new
    pp j.audit_subnets
  end

  desc 'Tag Audit'
  task all: %i[audit_vpcs audit_subnets audit_nodes]
end
