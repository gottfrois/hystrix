module Hystrix
  class CommandExecutor

    def lock
      @owner = Thread.current
    end

    def unlock
      @owner = nil
    end

    def locked?
      !!@owner
    end

    def run(command)
      command.run
    end

    private

    attr_reader :owner

  end
end
