describe Hystrix::Command do

  class FooCommand < Hystrix::Command

    pool_size 8

    def initialize(value:, wait: 0, fail: false)
      @value = value
      @wait  = wait
      @fail  = fail
    end

    def run
      sleep(@wait)
      fail 'error' if @fail
      @value
    end

    def fallback(exception)
      'fallback'
    end
  end

  before do
    Hystrix::Circuit.reset
  end

  after do
    Hystrix::Circuit.reset
  end

  describe '#execute' do

    it 'supports synchronous execution' do
      expect(FooCommand.new(value: 'foo').execute).to eq('foo')
    end

    it 'returns fallback value on exceptions' do
      expect(FooCommand.new(value: 'foo', fail: true).execute).to eq('fallback')
    end

    it 'raises the original exception if no fallback is defined' do
      class NoFallbackCommand < Hystrix::Command
        def run
          abort 'original_error'
        end
      end

      expect { NoFallbackCommand.new.execute }.to raise_error('original_error')
    end

    context 'when circuit is closed' do

      let(:circuit) { Hystrix::Circuit.new(name: 'foo') }

      before do
        allow(command).to receive(:circuit).and_return(circuit)
      end

      context 'and code run successfully' do

        let(:command) { FooCommand.new(value: 'foo') }

        it 'does not open the cirtcuit' do
          command.execute
          expect(circuit.open?).to eq(false)
        end

      end

      context 'and code fail' do

        let(:command) { FooCommand.new(value: 'foo', fail: true) }

        it 'does not open the circuit on first failure' do
          command.execute
          expect(circuit.open?).to eq(false)
        end

        it 'does open the circuit after a given number of failures' do
          10.times do
            command.execute
          end
          expect(circuit.open?).to eq(true)
        end

      end

    end

  end

  describe '#queue' do

    it 'supports asynchronous execution' do
      expect(FooCommand.new(value: 'foo').queue.value).to eq('foo')
    end

    it 'returns fallback value on exceptions' do
      expect(FooCommand.new(value: 'foo', fail: true).queue.value).to eq('fallback')
    end

  end

  it 'executes the fallback if its enable to get an executor to run the command' do
    pool = Hystrix::CommandExecutorPool.new(name: FooCommand.class.name, size: 1)

    slow = FooCommand.new(value: 'slow', wait: 1)
    slow.executor_pool = pool
    fast = FooCommand.new(value: 'fast', wait: 0)
    fast.executor_pool = pool

    f = slow.queue
    sleep(0.1)
    expect(fast.execute).to eq('fallback')
    expect(f.value).to eq('slow')
  end

end
