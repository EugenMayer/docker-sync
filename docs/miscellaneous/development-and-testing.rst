*********************
Development & testing
*********************

Development
===========

You do not really need a lot to start developing.

 - A local Ruby > 1.9 (I think we need that)

.. code-block:: shell

    git clone https://github.com/eugenmayer/docker-sync
    cd docker-sync
    bundle install
    gem uninstall -a docker-sync

**Important**: To properly develop, uninstall docker-sync as a gem so it is not used during the runs:
``gem uninstall -a docker-sync``.

Now you can:

.. code-block:: shell

    cd example
    thor sync:start

or

.. code-block:: shell

    thor stack:start

So you see, what is separated in to binaries in production ``docker-sync`` and ``docker-sync-stack`` is bundled under one namespace here, but prefixed.

General layout
--------------

Check libs folder.

 - SyncManager_: Main orchestrator to initialise the config, bootstrap ALL sync-endpoint-processes and start/stop those in threads
 - SyncProcess_: Does orchestrate/a manage ONE sync-endpoint. Selects the strategy on base of the config
 - Strategies: See below, specific implementations how to either sync or watch for changes.

.. _SyncManager: https://github.com/EugenMayer/docker-sync/blob/master/lib/docker_sync/sync_manager.rb
.. _SyncProcess: https://github.com/EugenMayer/docker-sync/blob/master/lib/docker_sync/sync_process.rb

Sync strategies
---------------

1. To add a new strategy for sync, copy one of those https://github.com/EugenMayer/docker-sync/tree/master/lib/docker_sync/sync_strategy here as your
2. Implement the general commands as they are implemented for rsync/unison - yes we do not have an strategy interface and no abstract class, since its ruby .. and well :)
3. Add your strategy here: https://github.com/EugenMayer/docker-sync/blob/master/lib/docker_sync/sync_process.rb#L31

Thats it.

Watch strategies
----------------

1. To add a new strategy for watch, copy one of those https://github.com/EugenMayer/docker-sync/tree/master/lib/docker_sync/watch_strategy here as your
2. Implement the general commands as they are implemented for fswatch
3. Add your strategy here: https://github.com/EugenMayer/docker-sync/blob/master/lib/docker_sync/sync_process.rb#L46

Thats it.

----

Testing
=======

Automated integration tests
---------------------------

.. code-block:: shell

    bundle install
    bundle exec rspec --format=documentation

Manual Tests (sync and performance)
-----------------------------------

.. tip::

    You can also use the docker-sync-boilerplate_.

Pull this repo and then

.. code-block:: shell

    cd docker-sync/example
    thor stack:start

Open a new shell and run

.. code-block:: shell

    cd docker-sync/example
    echo "NEWVALUE" >> data1/somefile.txt
    echo "NOTTHEOTHER" >> data2/somefile.txt

Check the docker-compose logs and you see that the files are updated.

Performance write test:

.. code-block:: shell

    docker exec -i -t fullexample_app time dd if=/dev/zero of=/var/www/test.dat bs=1024 count=100000

.. _docker-sync-boilerplate: https://github.com/EugenMayer/docker-sync-boilerplate
