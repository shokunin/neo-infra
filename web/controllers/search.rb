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
class Search < Sinatra::Base
  register Sinatra::RespondWith
  set :views, File.join(File.dirname(__FILE__), '..', '/views')

  post '/all' do
    if params['search'] =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/
      n = NeoInfra::Nodes.new
      respond_to do |wants|
        wants.html do
          erb :view_node,
              layout: :base_layout,
              locals: { node: n.search_nodes_by_ip(params['search']) }
        end
      end
    elsif params['search'] =~ /i-[a-f0-9]{6,20}/
      n = NeoInfra::Nodes.new
      respond_to do |wants|
        wants.html do
          erb :view_node,
              layout: :base_layout,
              locals: { node: n.search_nodes_by_node_id(params['search']) }
        end
      end
    else
      n = NeoInfra::Nodes.new
      respond_to do |wants|
        wants.html do
          erb :view_nodes,
              layout: :base_layout,
              locals: { nodes: n.search_nodes_by_name(params['search']) }
        end
      end
    end
  end
end
