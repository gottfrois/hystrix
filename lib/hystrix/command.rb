module Hystrix
  class Command
    include Concurrent::Async

    attr_accessor :executor_pool

    def execute
      result = nil
      executor = nil

      begin
        EventBus.notify('success') do
          circuit.bridge do
            executor = executor_pool.take
            result = executor.run(self)
          end
        end
      rescue NoMethodError => e
        raise e
      rescue Exception => e
        begin
          EventBus.notify('fallback') do
            result = fallback(e)
          end
        rescue NotImplementedError
          raise e.cause.present? ? e.cause : e
        end
      ensure
        executor.unlock if executor
      end

      return result
    end

    def queue
      async.execute
    end

    def run
      fail NotImplementedError
    end

    def fallback(*)
      fail NotImplementedError
    end

    def circuit
      @circuit ||= Circuit.new(name: self.class._pool_name)
    end

    def executor_pool
      @executor_pool || CommandExecutorPools.instance.get(name: self.class._pool_name, size: self.class._pool_size)
    end

    def self.pool_name(name)
      @_pool_name = name
    end

    def self.pool_size(size)
      @_pool_size = size
    end

    def self._pool_name
      @_pool_name || name
    end

    def self._pool_size
      @_pool_size || Concurrent.processor_count
    end

  end
end
