# frozen_string_literal: true

require 'yaml'

# NeoInfra Account information
module NeoInfra
  # load the config
  class Config
    attr_reader :config

    def initialize(cfg = 'config.yaml')
      @config = YAML.load_file(
        File.join(File.dirname(File.expand_path(__FILE__)),
                  '..', '..', cfg)
      )
    end

    def neo4j
      @config['neo4j']
    end

    def accounts
      @config['accounts']
    end
  end
end
