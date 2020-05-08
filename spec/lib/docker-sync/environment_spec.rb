require_relative "../../../lib/docker-sync/environment"

RSpec.describe DockerSync::Environment do
  describe :compose_file do
    def mock_compose_env(value)
      allow(ENV).to receive(:[]).with("COMPOSE_FILE").and_return(value)
    end

    it "should have the correct default" do
      mock_compose_env(nil)

      result = DockerSync::Environment.compose_file

      expect(result).to eq(['docker-compose.yml'])
    end

    it "respects ENV['COMPOSE_FILE']" do
      mock_compose_env('other-compose.yml')

      result = DockerSync::Environment.compose_file

      expect(result).to eq(['other-compose.yml'])
    end

    it "handles multiple files" do
      mock_compose_env('first-compose.yml:second-compose.yml')

      result = DockerSync::Environment.compose_file

      expect(result).to eq([
        'first-compose.yml',
        'second-compose.yml'
      ])
    end
    it "handles multiple files with semi-colon" do
      mock_compose_env('first-compose.yml;second-compose.yml')

      result = DockerSync::Environment.compose_file

      expect(result).to eq([
        'first-compose.yml',
        'second-compose.yml'
      ])
    end
  end
end