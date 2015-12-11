module Hystrix
  class CommandExecutorPool

    attr_reader :name, :size, :executors

    def initialize(name:, size:)
      @name               = name
      @size               = size
      @executors          = []
      @lock               = Mutex.new
      size.times { @executors << Hystrix::CommandExecutor.new }
    end

    def take
      lock.synchronize do
        executors.each do |executor|
          return executor.tap(&:lock) unless executor.locked?
        end
      end

      raise NoExecutorAvailableError
    end

    def shutdown
      lock.synchronize do
        until executors.count == 0 do
          executors.each_with_index do |executor, i|
            @executors[i] = nil unless executors[i].locked?
          end
          @executors.compact!
          sleep 0.1
        end
      end
    end

    private

    attr_reader :lock

  end
end
