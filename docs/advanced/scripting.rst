Scripting
=========

We use docker-sync as a library in our own docker-stack startup script. It starts the docker-compose stack using a Ruby gem `EugenMayer/docker-compose`_ all this wrapped into a thor task. So:

 - Start docker-sync
 - Start a docker-compose stack based on some arguments like --dev and load the specific docker-compose files for that using `xeger/docker-compose`_

docker-sync-stack is actually an example already, just see here:

1. You run the sync manager with run : https://github.com/EugenMayer/docker-sync/blob/master/tasks/stack/stack.thor#L37
2. But you do not call .join_threads after that like her https://github.com/EugenMayer/docker-sync/blob/master/tasks/sync/sync.thor#L36
3. Then you just continue doing what you want to script, in my case, i start a new blocking task - docker-compose. But you could do anything.

.. _EugenMayer/docker-compose: https://github.com/EugenMayer/docker-compose
.. _xeger/docker-compose: https://github.com/xeger/docker-compose


Simple scripting example
------------------------

.. code-block:: ruby

    require 'docker-sync/sync_manager'
    require 'docker-sync/dependencies'
    require 'docker-sync/config/project_config'

    # load the project config
    config = DockerSync::ProjectConfig.new(config_path: nil)
    DockerSync::Dependencies.ensure_all!(config)
    # now start the sync
    @sync_manager = Docker_sync::SyncManager.new(:config_path => config_path)
    @sync_manager.run() # do not call .join_threads now

    #### your stuff here
    @sync_manager.watch_stop()
    system('my-bash-script.sh')
    some_ruby_logic()
    system('other-tasks.sh')
    @sync_manager.sync()
    @sync_manager.watch_start()
    ### debootsrapping
    begin
      @sync_manager.join_threads
    rescue SystemExit, Interrupt
      say_status 'shutdown', 'Shutting down...', :blue

      @sync_manager.stop
    rescue Exception => e

      puts "EXCEPTION: #{e.inspect}"
      puts "MESSAGE: #{e.message}"

    end
