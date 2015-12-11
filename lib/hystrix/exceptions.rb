module Hystrix
  Exceptions               = Class.new(StandardError)
  NoExecutorAvailableError = Class.new(Exceptions)
end
