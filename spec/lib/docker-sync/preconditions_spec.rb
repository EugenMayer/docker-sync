describe Preconditions do
  describe '#check_all_preconditions' do
    context 'with simplest config' do
      it do
        expect(described_class).to receive(:docker_available)
        expect(described_class).to receive(:docker_running)
        expect(described_class).to receive(:unison_available)
        expect(described_class).to receive(:unox_available)
        expect(described_class).to receive(:macfsevents_available)
        expect(described_class).to receive(:watchdog_available)

        use_fixture 'simplest' do
          described_class.check_all_preconditions(load_config)
        end
      end
    end

    context 'with rsync config' do
      it do
        expect(described_class).to receive(:docker_available)
        expect(described_class).to receive(:docker_running)
        expect(described_class).not_to receive(:unison_available)
        expect(described_class).not_to receive(:unox_available)
        expect(described_class).not_to receive(:macfsevents_available)
        expect(described_class).not_to receive(:watchdog_available)

        use_fixture 'rsync' do
          described_class.check_all_preconditions(load_config)
        end
      end
    end
  end

  def load_config
    DockerSync::ProjectConfig.new
  end
end
