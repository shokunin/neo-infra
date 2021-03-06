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
class Views < Sinatra::Base
  register Sinatra::RespondWith
  set :views, File.join(File.dirname(__FILE__), '..', '/views')

  get '/vpcs' do
    w = NeoInfra::Vpcs.new
    respond_to do |wants|
      wants.html do
        erb :view_vpcs,
            layout: :base_layout,
            locals: { vpcs: w.list_vpcs }
      end
    end
  end

  get '/buckets' do
    j = NeoInfra::Aws.new
    respond_to do |wants|
      wants.html do
        erb :view_buckets,
            layout: :base_layout,
            locals: { buckets: j.list_buckets }
      end
    end
  end

  get '/dynamos' do
    j = NeoInfra::Aws.new
    respond_to do |wants|
      wants.html do
        erb :view_dynamos,
            layout: :base_layout,
            locals: { dynamos: j.list_dynamos }
      end
    end
  end

  get '/lambdas' do
    j = NeoInfra::Aws.new
    respond_to do |wants|
      wants.html do
        erb :view_lambdas,
            layout: :base_layout,
            locals: { lambdas: j.list_lambdas }
      end
    end
  end

  get '/rds' do
    j = NeoInfra::Aws.new
    respond_to do |wants|
      wants.html do
        erb :view_rds,
            layout: :base_layout,
            locals: { rds: j.list_rds }
      end
    end
  end

  get '/queues' do
    j = NeoInfra::Aws.new
    respond_to do |wants|
      wants.html do
        erb :view_queues,
            layout: :base_layout,
            locals: { queues: j.list_queues }
      end
    end
  end

  get '/graph/:graph_type' do
    respond_to do |wants|
      wants.html do
        erb :graphview,
            layout: :base_layout,
            locals: { graph_type: params['graph_type'] }
      end
    end
  end
end
