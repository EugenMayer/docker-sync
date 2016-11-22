require 'thor/shell'
# noinspection RubyResolve
require 'docker-sync/sync_strategy/rsync'
require 'docker-sync/sync_strategy/unison-onesided'
require 'docker-sync/sync_strategy/unison'
# noinspection RubyResolve
require 'docker-sync/watch_strategy/fswatch'
require 'docker-sync/watch_strategy/dummy'
require 'docker-sync/watch_strategy/unison'

module Docker_Sync
  class SyncProcess
    include Thor::Shell
    @options
    @sync_name
    @watch_thread
    @sync_strategy
    @watch_strategy

    # noinspection RubyStringKeysInHashInspection
    def initialize(sync_name, options)
      defaults = {
          'verbose' => false,
          'sync_host_ip' => get_host_ip
      }
      @sync_name = sync_name
      @options = defaults.merge(options)
      @sync_strategy = nil
      @watch_strategy = nil
      set_sync_strategy
      set_watch_strategy
    end

    def set_sync_strategy
      if @options.key?('sync_strategy')
        case @options['sync_strategy']
          when 'rsync'
            @sync_strategy = Docker_Sync::SyncStrategy::Rsync.new(@sync_name, @options)
          when 'unison-onesided'
            @sync_strategy = Docker_Sync::SyncStrategy::Unison_Onesided.new(@sync_name, @options)
          when 'unison'
            @sync_strategy = Docker_Sync::SyncStrategy::Unison.new(@sync_name, @options)
          else
            @sync_strategy = Docker_Sync::SyncStrategy::Rsync.new(@sync_name, @options)
        end
      else
        @sync_strategy = Docker_Sync::SyncStrategy::Rsync.new(@sync_name, @options)
      end
    end

    def set_watch_strategy
      if @options.key?('watch_strategy')
        case @options['watch_strategy']
          when 'fswatch'
            @watch_strategy = Docker_Sync::WatchStrategy::Fswatch.new(@sync_name, @options)
          when 'disable','dummy'
            @watch_strategy = Docker_Sync::WatchStrategy::Dummy.new(@sync_name, @options)
          when 'unison'
            @watch_strategy = Docker_Sync::WatchStrategy::Unison.new(@sync_name, @options)
          else
            @watch_strategy = Docker_Sync::WatchStrategy::Fswatch.new(@sync_name, @options)
        end
      else
        if @options['sync_strategy'] == 'unison'
          @watch_strategy = Docker_Sync::WatchStrategy::Unison.new(@sync_name, @options)
        else
          @watch_strategy = Docker_Sync::WatchStrategy::Fswatch.new(@sync_name, @options)
        end
      end
    end

    def get_host_ip
      return '127.0.0.1'
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
