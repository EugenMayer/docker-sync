require 'spec_helper'
require 'docker-sync/config/project_config'

RSpec.describe DockerSync::ProjectConfig do
  let(:default_sync_strategy)  do 
    if OS.linux?
      'native' 
    elsif OS.mac?
      'native_osx'
    else
      'unison'
    end
  end
  let(:default_watch_strategy) do 
    if OS.linux?
      'dummy'
    elsif OS.mac?
      'remotelogs'
    else
      'unison'
    end
  end

  subject { described_class.new }
  before do
    allow(DockerSync::Environment).to receive(:system).with('pgrep -q com.docker.hyperkit').and_return(true)
  end

  describe '#initialize' do

    describe 'minimum configuration with defaults' do
      it 'loads simplest config' do
        use_fixture 'simplest' do
          expect(subject.to_h).to eql({
            'version' => '2',
            'options' => {
              'project_root' => 'pwd',
            },
            'syncs' => {
              'simplest-sync' => {
                'src' => "#{fixture_path 'simplest'}/app",
                'dest' => '/var/www',
                'sync_strategy' => default_sync_strategy,
                'watch_strategy' => default_watch_strategy
              }
            }
          })
        end
      end
    end

    describe 'overwriting defaults with explicit configuration' do
      it 'loads rsync config' do
        use_fixture 'rsync' do
          expect(subject.to_h).to eql({
            'version' => '2',
            'options' => {
              'project_root' => 'pwd',
              'verbose' => true,
            },
            'syncs' => {
              'appcode-rsync-sync' => {
                'src' => "#{fixture_path 'rsync'}/app",
                'dest' => '/var/www',
                'sync_host_ip' => 'localhost',
                'sync_host_port' => 10872,
                'sync_strategy' => 'rsync',
                'watch_strategy' => 'fswatch'
              }
            }
          })
        end
      end

      it 'loads unison config' do
        use_fixture 'unison' do
          expect(subject.to_h).to eql({
            'version' => '2',
            'options' => {
              'project_root' => 'pwd',
              'verbose' => true,
            },
            'syncs' => {
              'appcode-unison-sync' => {
                'src' => "#{fixture_path 'unison'}/app",
                'dest' => '/var/www',
                'sync_excludes' => ['ignored_folder', '.ignored_dot_folder'],
                'sync_strategy' => 'unison',
                'watch_strategy' => 'unison'
              }
            }
          })
        end
      end

      it 'loads dummy config' do
        use_fixture 'dummy' do
          expect(subject.to_h).to eql({
            'version' => '2',
            'options' => {
              'project_root' => 'pwd',
            },
            'syncs' => {
              'appcode-dummy-sync' => {
                'src' => "#{fixture_path 'dummy'}/app",
                'dest' => '/var/www',
                'sync_strategy' => default_sync_strategy,
                'watch_strategy' => 'dummy'
              }
            }
          })
        end
      end
    end

    describe 'parent directory lookup' do
      it 'able to lookup into parent directory' do
        use_fixture 'simplest/app' do
          expect(subject.to_h).to eql({
            'version' => '2',
            'options' => {
              'project_root' => 'pwd',
            },
            'syncs' => {
              'simplest-sync' => {
                'src' => "#{fixture_path 'simplest'}/app/app",
                'dest' => '/var/www',
                'sync_strategy' => default_sync_strategy,
                'watch_strategy' => default_watch_strategy,
              }
            }
          })
        end
      end
    end

    describe 'project_root (used for expanding src to absolute_path)' do
      it 'default to pwd' do
        use_fixture 'simplest/app' do
          expect(subject.to_h).to eql({
            'version' => '2',
            'options' => {
              'project_root' => 'pwd',
            },
            'syncs' => {
              'simplest-sync' => {
                'src' => "#{fixture_path 'simplest'}/app/app",
                'dest' => '/var/www',
                'sync_strategy' => default_sync_strategy,
                'watch_strategy' => default_watch_strategy,
              }
            }
          })
        end
      end

      it 'can be overwritten to use config_path' do
        use_fixture 'project_root/app' do
          expect(subject.to_h).to eql({
            'version' => '2',
            'options' => {
              'project_root' => 'config_path',
            },
            'syncs' => {
              'project_root-sync' => {
                'src' => "#{fixture_path 'project_root'}/app",
                'dest' => '/var/www',
                'sync_strategy' => default_sync_strategy,
                'watch_strategy' => default_watch_strategy
              }
            }
          })
        end
      end
    end

    describe 'explicit config_path' do
      subject { described_class.new(config_path: config_path) }

      context 'given config path exists' do
        let(:config_path) { File.join(fixture_path('simplest'), 'docker-sync.yml') }

        it 'load the config regardless of current working directory' do
          expect(subject.to_h).to eql({
            'version' => '2',
            'options' => {
              'project_root' => 'pwd',
            },
            'syncs' => {
              'simplest-sync' => {
                'src' => "#{Dir.pwd}/app",
                'dest' => '/var/www',
                'sync_strategy' => default_sync_strategy,
                'watch_strategy' => default_watch_strategy
              }
            }
          })
        end
      end

      context 'given config path does not exists' do
        let(:config_path) { File.join(fixture_path('foo'), 'bar.yml') }

        it 'raise error_missing_given_config' do
          expect {
            subject
          }.to raise_error("Config could not be loaded from #{config_path} - it does not exist")
        end
      end

      context 'given config path is an empty string' do
        let(:config_path) { '' }

        it 'fall back into default project config' do
          expect(DockerSync::ConfigLocator).to receive(:lookup_project_config_path).and_call_original

          use_fixture('simplest') do
            subject
          end
        end
      end
    end

    describe 'explicit config_string' do
      let(:config_string) {
        # not using squiggly heredoc since we want to support ruby < 2.3
        <<-YAML
version: "2"

syncs:
  #IMPORTANT: ensure this name is unique and does not match your other application container name
  config-string-sync: #tip: add -sync and you keep consistent names als a convention
    src: './foo'
    dest: '/foo/bar'
  YAML
      }

      subject { described_class.new(config_string: config_string) }

      it 'load the config string' do
        expect(subject.to_h).to eql({
          'version' => '2',
          'options' => {
            'project_root' => 'pwd',
          },
          'syncs' => {
            'config-string-sync' => {
              'src' => "#{Dir.pwd}/foo",
              'dest' => '/foo/bar',
              'sync_strategy' => default_sync_strategy,
              'watch_strategy' => default_watch_strategy
            }
          }
        })
      end
    end

    describe 'dynamic configuration with ENV and interpolation' do
      it 'reads from .env and interpolate source yml' do
        use_fixture 'dynamic-configuration-dotenv' do
          expect(subject.to_h).to eql({
            'version' => '2',
            'options' => {
              'project_root' => 'pwd',
              'verbose' => true
            },
            'syncs' => {
              'docker-boilerplate-unison-sync' => {
                'src' => "#{fixture_path 'dynamic-configuration-dotenv'}/app",
                'dest' => '/var/www',
                'sync_excludes' => ['ignored_folder', '.ignored_dot_folder' ],
                'sync_strategy' => default_sync_strategy,
                'watch_strategy' => default_watch_strategy
              }
            }
          })
        end
      end
    end

    describe 'error handling' do
      it 'raise ERROR_MISSING_CONFIG_VERSION if version is missing from setting' do
        use_fixture 'missing_version' do
          expect { subject }.to raise_error(DockerSync::ProjectConfig::ERROR_MISSING_CONFIG_VERSION)
        end
      end

      it 'raise ERROR_MISMATCH_CONFIG_VERSION if version number does not match' do
        use_fixture 'mismatch_version' do
          expect { subject }.to raise_error(DockerSync::ProjectConfig::ERROR_MISMATCH_CONFIG_VERSION)
        end
      end

      it 'raise ERROR_MISSING_SYNCS if no syncs defined' do
        use_fixture 'missing_syncs' do
          expect { subject }.to raise_error(DockerSync::ProjectConfig::ERROR_MISSING_SYNCS)
        end
      end

      it 'raise if sync config is missing src' do
        use_fixture 'missing_syncs_src' do
          expect {
            subject
          }.to raise_error(
            'missing-syncs-src-sync does not have src configuration value set - this is mandatory'
          )
        end
      end

      it 'raise if sync config is missing sync_host_port when sync_strategy is rsync' do
        use_fixture 'missing_syncs_sync_host_port' do
          expect {
            subject
          }.to raise_error(
            'missing-syncs-sync_host_port-sync does not have sync_host_port configuration value set - this is mandatory'
          )
        end
      end
    end
  end

  describe '#unison_required?' do
    it do
      allow(DockerSync::Environment).to receive(:system).with('pgrep -q com.docker.hyperkit').and_return(true)

      use_fixture 'simplest' do
        if OS.linux? || OS.mac?
          is_expected.not_to be_unison_required
        else
          is_expected.to be_unison_required
        end
      end
    end
    it do use_fixture 'rsync' do is_expected.not_to be_unison_required end end
    it do use_fixture 'unison' do is_expected.to be_unison_required end end
  end
end
