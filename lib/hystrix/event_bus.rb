require 'active_support/notifications'

module Hystrix
  class EventBus

    def self.notify(event_name, payload = {}, &block)
      ::ActiveSupport::Notifications.instrument(event_name, payload, &block)
    end

    def self.subscribe(event_name, &block)
      ::ActiveSupport::Notifications.subscribe event_name do |*args|
        event = ::ActiveSupport::Notifications::Event.new(*args)
        block.call(event)
      end
    end

  end
end
