# frozen_string_literal: true

require 'sinatra'
require 'sinatra/base'
require 'sinatra/contrib'

# Display the Top level Web page
class Toppage < Sinatra::Base
  register Sinatra::RespondWith
  set :public_folder, File.join(File.dirname(__FILE__), '..', '/static')
  set :views, File.join(File.dirname(__FILE__), '..', '/views')

  # just respond with OK, so that monitoring knows that the application is running
  get '/monitor' do
    'OK'
  end

  get '/' do
    respond_to do |wants|
      wants.html do
        erb :index,
            layout: :base_layout
      end
    end
  end
end
