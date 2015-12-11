describe Hystrix::CommandExecutorPool do

  it { expect(described_class.new(name: 'test', size: 10).executors.count).to eq(10) }

  describe '#take' do

    it 'fails if all executors are locked' do
      pool = described_class.new(name: 'test', size: 1)

      aggregate_failures do
        expect(pool.take).not_to be_nil
        expect { pool.take }.to raise_error(Hystrix::NoExecutorAvailableError)
      end
    end

    it 're-uses executors after they are unlocked' do
      pool = described_class.new(name: 'test', size: 1)
      executor = pool.take
      executor.unlock

      expect(pool.take.object_id).to eq(executor.object_id)
    end

    it 'fails if there are no executors configured' do
      pool = described_class.new(name: 'test', size: 0)
      expect { pool.take }.to raise_error(Hystrix::NoExecutorAvailableError)
    end

  end

  describe '#shutdown' do

    it 'shuts down all registered executors' do
      pool = described_class.new(name: 'test', size: 10)
      pool.shutdown
      expect(pool.executors.count).to eq(0)
    end

    it 'lets commands finish when shutting down' do
      class SleepCommand < Hystrix::Command
        def run
          sleep 1
          'foo'
        end
      end

      pool = described_class.new(name: 'test', size: 10)
      command = SleepCommand.new
      command.executor_pool = pool
      future = command.queue

      sleep 0.1

      pool.shutdown

      expect(pool.executors.count).to eq(0)
      expect(future.value).to eq('foo')
    end

  end

end
