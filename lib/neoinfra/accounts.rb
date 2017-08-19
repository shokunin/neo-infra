# frozen_string_literal: true

require 'yaml'
require 'fog'
require 'neo4j'

# NeoInfra Account information
module NeoInfra
  models_dir = File.join(
    File.dirname(File.expand_path(__FILE__)), '..', 'models'
  )

  $LOAD_PATH.unshift(models_dir) unless
    $LOAD_PATH.include?(models_dir) || $LOAD_PATH.include?(models_dir)

  # Provide informations about the accounts available
  class Accounts
    attr_reader :accounts

    def initialize
      @accounts = YAML.load_file(
        File.join(File.dirname(File.expand_path(__FILE__)),
                  '..', '..', 'accounts.yaml')
      )
    end

    def list
      accounts
    end
  end
end
