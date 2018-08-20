# frozen_string_literal: true

lib_dir = File.join(File.dirname(File.expand_path(__FILE__)))
$LOAD_PATH.unshift(lib_dir) unless
  $LOAD_PATH.include?(lib_dir) || $LOAD_PATH.include?(lib_dir)

models_dir = File.join(File.dirname(File.expand_path(__FILE__)), '..', 'models')
$LOAD_PATH.unshift(models_dir) unless
  $LOAD_PATH.include?(models_dir) || $LOAD_PATH.include?(models_dir)

# The supplies all of the various neoinfra info
module NeoInfra
  require 'neoinfra/config'
  require 'neoinfra/audit'
  require 'neoinfra/accounts'
  require 'neoinfra/aws'
  require 'neoinfra/vpcs'
  require 'neoinfra/nodes'
  require 'neoinfra/cloudwatch'
end
