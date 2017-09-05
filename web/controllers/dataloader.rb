lib_dir = File.join(File.dirname(File.expand_path(__FILE__)), '..', '..', 'lib')
$LOAD_PATH.unshift(lib_dir) unless
  $LOAD_PATH.include?(lib_dir) || $LOAD_PATH.include?(lib_dir)

require 'neoinfra'
require 'sinatra'
require 'sinatra/base'
require 'sinatra/respond_to'

class Dataloader < Sinatra::Base
  register Sinatra::RespondTo
  set :views, File.join(File.dirname(__FILE__), '..', '/views')

  get '/all' do
    respond_to do |wants|
      wants.html {  erb :load_all,
      :layout => :base_layout }
    end
  end

  get '/accounts' do
    j = NeoInfra::Accounts.new
    j.load
    status 200
    "Loaded Accounts: #{j.list_names.sort.join(' ')}"
  end

  get '/regions' do
    j = NeoInfra::Aws.new
    j.load_regions
    status 200
    #{}"Loaded #{j.region_count} regions, #{j.az_count} availablity zones"
    "suck"
  end

  get '/vpcs' do
    j = NeoInfra::Vpcs.new
    #j.load_vpcs
    status 200
    "Loaded #{j.default_vpc_count} default vpcs, #{j.non_default_vpc_count} non-default vpcs"

  end

end
