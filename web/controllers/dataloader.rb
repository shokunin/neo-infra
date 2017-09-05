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
    #j.load
    status 200
    "Loaded Accounts: #{j.list_names.sort.join(' ')}"
  end

end
