describe Hystrix::Command do

  class FooCommand < Hystrix::Command

    pool_size 8
    pool_name 'bar'

    def initialize(value:, wait: 0, fail: false)
      @value = value
      @wait = wait
      @fail = fail
    end

    def run
      sleep(@wait)
      abort 'error' if @fail
      @value
    end

    def fallback(exception)
      'fallback'
    end
  end

  describe '#execute' do

    it 'supports synchronous execution' do
      expect(FooCommand.new(value: 'foo').execute).to eq('foo')
    end

    it 'returns fallback value on exceptions' do
      expect(FooCommand.new(value: 'foo', fail: true).execute).to eq('fallback')
    end

    it 'executes only once' do
      command = FooCommand.new(value: 'foo')
      expect(command.execute).to eq('foo')
      expect { command.execute }.to raise_error
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

      let(:circuit) { Stoplight::Light.new('foo', &code) }

      before do
        allow(Stoplight::Light).to receive(:new).and_return(circuit)
      end

      context 'and code run successfully' do

        let(:code) { -> { true } }

        it 'does not open the cirtcuit' do
          FooCommand.new(value: 'foo').execute
          expect(circuit.color).to eq(Stoplight::Color::GREEN)
        end

      end

      context 'and code fails' do

        let(:code) { -> { fail } }

        it 'does not open the circuit on first failure' do
          FooCommand.new(value: 'foo').execute
          expect(circuit.color).to eq(Stoplight::Color::GREEN)
        end

        it 'does open the circuit after a given number of failures' do
          3.times do
            FooCommand.new(value: 'foo').execute
          end
          expect(circuit.color).to eq(Stoplight::Color::RED)
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

    it 'executes only once' do
      command = FooCommand.new(value: 'foo')
      expect(command.queue.value).to eq('foo')
      expect { command.queue.value }.to raise_error
    end

  end

  it 'executes the fallback if its enable to get an executor to run the command' do
    pool = Hystrix::CommandExecutorPool.new(name: 'foo', size: 1)

    c1 = FooCommand.new(value: 'c1', wait: 1)
    c1.executor_pool = pool
    c2 = FooCommand.new(value: 'c2')
    c2.executor_pool = pool

    f1 = c1.queue
    expect(c2.execute).to eq('fallback')
    expect(f1.value).to eq('c1')
  end

end
