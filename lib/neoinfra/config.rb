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

      @config.keys.each do |c|
        define_singleton_method(c.to_sym) do
          @config[c]
        end
      end
    end
  end
end
