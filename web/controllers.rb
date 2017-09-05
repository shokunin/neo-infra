# Dynamically pick up all of the controllers
Dir.glob(File.join(File.dirname(__FILE__), 'controllers', '*.rb')).select{|c| File.basename(c) != 'controllers.rb' }.each do |x|
  require x
end
