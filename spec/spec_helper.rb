$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pry'
require 'hystrix'

RSpec.configure do |config|
  config.mock_with :rspec
end
