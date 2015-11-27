require 'singleton'

module Hystrix
  class CommandExecutorPools
    include Singleton

    attr_reader :pools

    def initialize
      @lock = Mutex.new
      @pools = {}
    end

    def get(name:, size: Celluloid.cores)
      lock.synchronize do
        pools[name] ||= Hystrix::CommandExecutorPool.new(name: name, size: size)
      end
    end

    def shutdown
      lock.synchronize do
        pools.values.each(&:shutdown)
      end
    end

    private

    attr_reader :lock

  end
end
