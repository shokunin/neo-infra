# controllers to load
require (File.join(File.dirname(__FILE__), 'web', 'controllers'))

# serve up static assets using rack
map "/js" do
  run Rack::Directory.new("#{File.join(File.dirname(__FILE__), 'web', 'static', 'js')}")
end

# serve up static assets using rack
map "/bootstrap" do
  run Rack::Directory.new("#{File.join(File.dirname(__FILE__), 'web', 'static', 'js')}")
end

map "/" do
    run Toppage
end
