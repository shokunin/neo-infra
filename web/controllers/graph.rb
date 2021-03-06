# frozen_string_literal: true

lib_dir = File.join(File.dirname(File.expand_path(__FILE__)), '..', '..', 'lib')
$LOAD_PATH.unshift(lib_dir) unless
  $LOAD_PATH.include?(lib_dir) || $LOAD_PATH.include?(lib_dir)

require 'json'
require 'neoinfra'
require 'sinatra'
require 'sinatra/base'
require 'sinatra/contrib'

# Handle loading data into the graph db
class Graph < Sinatra::Base
  register Sinatra::RespondWith
  set :views, File.join(File.dirname(__FILE__), '..', '/views')

  get '/vpcs' do
    headers('Content-Type' => "text/csv")
    g = NeoInfra::Graph.new
    g.graph_vpcs
  end

  get '/buckets' do
    headers('Content-Type' => "text/csv")
    g = NeoInfra::Graph.new
    g.graph_buckets
  end

  get '/queues' do
    headers('Content-Type' => "text/csv")
    g = NeoInfra::Graph.new
    g.graph_queues
  end

end
