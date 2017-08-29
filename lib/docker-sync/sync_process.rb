require 'thor/shell'
# noinspection RubyResolve
require 'docker-sync/sync_strategy/rsync'
require 'docker-sync/sync_strategy/unison'
require 'docker-sync/sync_strategy/native'
require 'docker-sync/sync_strategy/native_osx'

# noinspection RubyResolve
require 'docker-sync/watch_strategy/fswatch'
require 'docker-sync/watch_strategy/dummy'
require 'docker-sync/watch_strategy/unison'
require 'docker-sync/watch_strategy/remotelogs'

module DockerSync
  class SyncProcess
    include Thor::Shell
    @options
    @sync_name
    @watch_thread
    @sync_strategy
    @watch_strategy

    # noinspection RubyStringKeysInHashInspection
    def initialize(sync_name, options)
      @sync_name = sync_name

      defaults = {
          'verbose' => false,
      }

      # even if sync_host_ip is set, if it is set to auto, enforce the default
      if !options.key?('sync_host_ip') || options['sync_host_ip'] == 'auto' || options['sync_host_ip'] == ''
        options['sync_host_ip'] = get_host_ip_default
      end

      @options = defaults.merge(options)
      @sync_strategy = nil
      @watch_strategy = nil
      set_sync_strategy
      set_watch_strategy
    end

    def set_sync_strategy
      case @options['sync_strategy']
      when 'rsync'
        @sync_strategy = DockerSync::SyncStrategy::Rsync.new(@sync_name, @options)
      when 'unison'
        @sync_strategy = DockerSync::SyncStrategy::Unison.new(@sync_name, @options)
      when 'native'
        @sync_strategy = DockerSync::SyncStrategy::Native.new(@sync_name, @options)
      when 'native_osx'
        @sync_strategy = DockerSync::SyncStrategy::NativeOsx.new(@sync_name, @options)
      else
        raise "Unknown sync_strategy #{@options['sync_strategy']}"
      end
    end

    def set_watch_strategy
      case @options['watch_strategy']
      when 'fswatch'
        @watch_strategy = DockerSync::WatchStrategy::Fswatch.new(@sync_name, @options)
      when 'dummy'
        @watch_strategy = DockerSync::WatchStrategy::Dummy.new(@sync_name, @options)
      when 'unison'
        @watch_strategy = DockerSync::WatchStrategy::Unison.new(@sync_name, @options)
      when 'remotelogs'
        @watch_strategy = DockerSync::WatchStrategy::Remote_logs.new(@sync_name, @options)
      else
        raise "Unknown watch_strategy #{@options['watch_strategy']}"
      end
    end

    def get_host_ip_default
      return '127.0.0.1' unless Dependencies::Docker::Driver.docker_toolbox?

      cmd = 'docker-machine ip $(docker-machine active)'
      stdout, stderr, exit_status = Open3.capture3(cmd)
      unless exit_status.success?
        raise "Error getting sync_host_ip automatically, exit code #{$?.exitstatus} ... #{stderr}"
      end
      stdout.gsub("\n",'')
    end

    def run
      @sync_strategy.run
      @watch_strategy.run
    end

    def stop
      @sync_strategy.stop
      @watch_strategy.stop
    end

    def clean
      @sync_strategy.clean
      @watch_strategy.clean
    end

    def sync
      # TODO: probably use run here
      @sync_strategy.sync
    end

    def start_container
      @sync_strategy.start_container
    end

    def watch
      @watch_strategy.run
    end

    def watch_fork
      return @watch_strategy.watch_fork
    end

    def watch_thread
      return @watch_strategy.watch_thread
    end
  end
end
