# frozen_string_literal: true

# Dynamically pick up all of the controllers

Dir.glob(
  File.join(
    File.dirname(__FILE__), 'controllers', '*.rb'
  )
).reject { |c| File.basename(c) == 'controllers.rb' }.each do |x|
  begin
    require x
  rescue
    puts "unable to load: #{x}"
  end
end
