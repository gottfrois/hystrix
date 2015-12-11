module Hystrix
  module Loggable

    attr_accessor :logger

    def logger
      @logger ||= rails_logger || default_logger
    end

    private

    def rails_logger
      defined?(::Rails) && ::Rails.respond_to?(:logger) && ::Rails.logger
    end

    def default_logger
      ::Logger.new($stdout).tap do |logger|
        logger.level = ::Logger::INFO
      end
    end

  end
end
