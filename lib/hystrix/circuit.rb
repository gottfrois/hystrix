require 'stoplight'

module Hystrix
  class Circuit

    def initialize(name, timeout: 10, threshold: 3, &code)
      ::Stoplight::Light.new(name, &code)
        .with_timeout(timeout)
        .with_threshold(threshold)
        .run
    end

  end
end
