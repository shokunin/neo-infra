# frozen_string_literal: true

# controllers to load
require File.join(File.dirname(__FILE__), 'web', 'controllers')

# serve up static assets using rack
# map "/js" do
#  run Rack::Directory.new("#{File.join(File.dirname(__FILE__), 'web', 'static', 'js')}")
# end

map '/' do
  run Toppage
end

map '/load' do
  run Dataloader
end

map '/view' do
  run Views
end

map '/search' do
  run Search
end

map '/graph' do
  run Graph
end
