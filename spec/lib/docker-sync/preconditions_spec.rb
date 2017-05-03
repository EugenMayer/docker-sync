require 'docker-sync/preconditions/strategy'
require 'docker-sync/preconditions/preconditions_osx'
require 'docker-sync/sync_strategy/unison'
require 'pp'
describe DockerSync::Preconditions::Strategy do
  specify '.instance always refers to the same instance' do
    expect(DockerSync::Preconditions::Strategy.instance).to be_a_kind_of DockerSync::Preconditions::Strategy
    expect(DockerSync::Preconditions::Strategy.instance).to equal DockerSync::Preconditions::Strategy.instance
  end


  subject {
    Singleton.__init__(DockerSync::Preconditions::Strategy)
    described_class.instance
  }
  describe '#check_all_preconditions' do

    context 'with unison config' do
      it do
        #expect(subject).to receive(:unison_available)
        allow(subject.strategy).to receive(:unison_available) { true }
        expect(subject).to receive(:unison_available)

        use_fixture 'unison' do
          config = load_config
          Docker_Sync::SyncStrategy::Unison.new('appcode-unison-sync',config['syncs']['appcode-unison-sync'])
        end
      end
    end

    context 'with check all unison precondition' do
      it do
        allow(subject.strategy).to receive(:should_run_precondition?) { true }
        allow(subject.strategy).to receive(:docker_available) { true }
        allow(subject.strategy).to receive(:docker_running) { true }
        allow(subject.strategy).to receive(:unison_available) { true }
        #allow(subject.strategy).to receive(:unox_available) { true }

        expect(subject.strategy).to receive(:docker_available)
        expect(subject.strategy).to receive(:docker_running)
        expect(subject.strategy).to receive(:unison_available)
        #expect(described_class.instance.strategy).to receive(:unox_available)

        use_fixture 'unison' do
          subject.check_all_preconditions(load_config)
        end
      end
    end

    context 'if osx, osx strategy is picked' do
      it do
        allow(DockerSync::Preconditions::Strategy).to receive(:is_osx) { true }
        Singleton.__init__(DockerSync::Preconditions::Strategy)
        expect(subject.strategy).to be_a(DockerSync::Preconditions::Osx)
      end
    end

    context 'if linux, linux strategy is picked' do
      it do
        allow(DockerSync::Preconditions::Strategy).to receive(:is_osx) { false }
        allow(DockerSync::Preconditions::Strategy).to receive(:is_linux) { true }
        Singleton.__init__(DockerSync::Preconditions::Strategy)
        expect(subject.strategy).to be_a(DockerSync::Preconditions::Linux)
      end
    end

    context 'on osx without brew, skip precondition tests' do
      it do
        allow(DockerSync::Preconditions::Strategy).to receive(:is_osx) { true }
        Singleton.__init__(DockerSync::Preconditions::Strategy)
        expect(subject.strategy).to be_a(DockerSync::Preconditions::Osx)

        Singleton.__init__(DockerSync::Preconditions::Strategy)
        allow(subject.strategy).to receive(:has_brew?) { false }

        expect(subject.strategy.send(:should_run_precondition?, true)).to eq(false)
      end
    end


    context 'on osx with brew, have precondition tests' do
      it do
        allow(DockerSync::Preconditions::Strategy).to receive(:is_osx) { true }
        Singleton.__init__(DockerSync::Preconditions::Strategy)
        expect(subject.strategy).to be_a(DockerSync::Preconditions::Osx)

        Singleton.__init__(DockerSync::Preconditions::Strategy)
        allow(subject.strategy).to receive(:has_brew?) { true }

        expect(subject.strategy.send(:should_run_precondition?, true)).to eq(true)
      end
    end

    context 'without docker installed, do raise an exception' do
      it do
        Singleton.__init__(DockerSync::Preconditions::Strategy)

        allow(subject.strategy).to receive(:docker_available).and_raise('docker not here')
        allow(subject.strategy).to receive(:should_run_precondition?) { true }

        use_fixture 'simplest' do
          expect { subject.check_all_preconditions(load_config) }.to raise_error('docker not here')
        end
      end
    end

    context 'without docker running, do raise an exception' do
      it do
        Singleton.__init__(DockerSync::Preconditions::Strategy)

        allow(subject.strategy).to receive(:docker_available) {true}
        allow(subject.strategy).to receive(:docker_running).and_raise('docker stopped')

        use_fixture 'simplest' do
          expect { subject.check_all_preconditions(load_config) }.to raise_error('docker stopped')
        end
      end
    end

    context 'with rsync config' do
      it do
        allow(subject.strategy).to receive(:should_run_precondition?) { true }
        allow(subject.strategy).to receive(:docker_available) { true }
        allow(subject.strategy).to receive(:docker_running) { true }
        allow(subject.strategy).to receive(:rsync_available) { true }

        expect(subject.strategy).to receive(:docker_available)
        expect(subject.strategy).to receive(:docker_running)
        expect(subject.strategy).not_to receive(:unison_available)
        expect(subject.strategy).to receive(:rsync_available)

        use_fixture 'rsync' do
          subject.check_all_preconditions(load_config)
        end
      end
    end
  end

  def load_config
    DockerSync::ProjectConfig.new
  end
end
