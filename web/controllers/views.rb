# frozen_string_literal: true

lib_dir = File.join(File.dirname(File.expand_path(__FILE__)), '..', '..', 'lib')
$LOAD_PATH.unshift(lib_dir) unless
  $LOAD_PATH.include?(lib_dir) || $LOAD_PATH.include?(lib_dir)

require 'json'
require 'neoinfra'
require 'sinatra'
require 'sinatra/base'
require 'sinatra/respond_to'

# Handle loading data into the graph db
class Views < Sinatra::Base
  register Sinatra::RespondTo
  set :views, File.join(File.dirname(__FILE__), '..', '/views')

  get '/vpcs' do
    status 200
    puts Vpc
  end

  get '/buckets' do
    j = NeoInfra::Aws.new
    respond_to do |wants|
      wants.html {
        erb :view_buckets,
        :layout => :base_layout,
        :locals => {:buckets => j.list_buckets}
      }
    end
  end

end
