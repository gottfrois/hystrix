describe Hystrix::CommandExecutor do

  let(:instance) { described_class.new }

  describe '#lock' do

    it { expect { instance.lock }.to change { instance.locked? }.from(false).to(true) }

  end

  describe '#unlock' do

    before do
      instance.lock
    end

    it { expect { instance.unlock }.to change { instance.locked? }.from(true).to(false) }

  end

  describe '#run' do

    let(:command) { instance_double('Hystrix::Command') }

    it 'executes specified command' do
      expect(command).to receive(:run)
      instance.run(command)
    end

  end

end
