module Hystrix
  class Command
    include Celluloid

    attr_accessor :executor_pool

    def execute
      result = nil
      executor = nil

      begin
        Circuit.new(self.class._pool_name) do
          executor = executor_pool.take
          result = executor.run(self)
        end
      rescue Exception => original_exception
        begin
          result = fallback(original_exception)
        rescue NotImplementedError
          raise original_exception
        end
      ensure
        executor.unlock if executor
        terminate
      end

      return result
    end

    def queue
      future.execute
    end

    def run
      fail NotImplementedError
    end

    def fallback(*)
      fail NotImplementedError
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
      @_pool_size || Celluloid.cores
    end

  end
end
