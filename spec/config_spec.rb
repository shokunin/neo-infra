# frozen_string_literal: true

lib_dir = File.join(File.dirname(File.expand_path(__FILE__)), '..', 'lib')
$LOAD_PATH.unshift(lib_dir) unless
  $LOAD_PATH.include?(lib_dir) || $LOAD_PATH.include?(lib_dir)

require 'neoinfra/config'

describe NeoInfra do
  before(:each) do
    @test_config = NeoInfra::Config.new('config.yaml.example')
  end

  it 'loads test accounts' do
    expect(@test_config.accounts.length).to eql(1)
  end

  it 'neo4j default host is set' do
    expect(@test_config.neo4j[:host]).to eql('localhost')
  end
end
