********
Commands
********

Sync commands (``docker-sync``)
===============================

Generally you can just list all the help in the cli by:

.. code-block:: shell

    docker-sync help

Start
-----

.. code-block:: shell

    docker-sync start

.. tip::

    See :ref:`sync-stack-commands` on how ``docker-sync-stack start`` works to start sync / compose at the same time.

This creates and starts the sync containers, watchers and the sync itself. It blocks your shell and you should leave it running in the background. When you are done, just press ``CTRL-C`` and the containers will be stopped ( not removed ).

Running start the second time will be a lot faster, since containers and volumes are reused.

.. tip::

    You can use ``-n <sync-endpoint-name>`` to only start one of your configured sync-endpoints.

Sync
----

.. code-block:: shell

    docker-sync sync

This forces docker-sync to sync the host files to the sync-containers. You must have the containers running already (``docker-sync start``). Use this as a manual trigger, if either the change-watcher failed or you try something special / an integration

.. tip::

    You can use ``-n <sync-endpoint-name>`` to only sync one of your configured sync-endpoints.

List
----

.. code-block:: shell

    docker-sync list

List all available/configured sync-endpoints configured for the current project.

Clean
-----

After you are done and want to free up space or switch to a different project, you might want to release the sync containers and volumes by

.. code-block:: shell

    docker-sync clean

This will not delete anything on your host source code folders or similar, it just removes the container for sync and its volumes. It does not touch your application stack.

----

.. _sync-stack-commands:

Sync stack commands (``docker-sync-stack``)
===========================================

With docker-sync there comes docker-sync-stack ( from 0.0.10 ). Using this, you can start the sync service and docker compose with one single command. This is based on the gem docker-compose_.

Start
-----

.. code-block:: shell

    docker-sync-stack start

This will first start the sync service like ``docker-sync start`` and then start your compose stack like ``docker-compose up``.

You do not need to run ``docker-sync start`` beforehand!

**This is very convenient so you only need one shell, one command to start working and CTRL-C to stop.**

Clean
-----

.. code-block:: shell

    docker-sync-stack clean

This cleans the sync-service like ``docker-sync clean`` and also removed the application stack like ``docker-compose down``.

.. _docker-compose: https://github.com/xeger/docker-compose

----

.. _daemon-mode:

Daemon mode
===========

Docker-sync in daemon mode
--------------------------

Beginning with version **0.4.0** Daemon mode is now the default, just use ``docker-sync start``. ``docker-sync-daemon`` is deprecated.

-----

Beginning with version **0.2.0**, docker-sync has the ability to run in a daemonized (background) mode.

In general you now run `docker-sync-daemon` to start in daemonized mode, type ``docker-sync-daemon <enter>`` to see all options

Start
-----

The `docker-sync-daemon start` command has the following options to help configure daemon mode:

- ``--app_name`` (``--name``), The name to use in the filename for the ``pid`` and ``output`` files (default: 'daemon')
- ``--dir``, The directory to place the ``pid`` and ``output`` files (default: './.docker-sync')
- ``--logd``, Whether or not to log the output (default: true)

Stop
----

The ``docker-sync-daemon`` stop command is available to stop the background process. It also takes the ``--app_name`` and ``--dir`` arguments.

Log
---

The ``docker-sync-daemon logs`` command is a handy shortcut to tail the logs from the daemonized process, in addition to the ``--app_name`` and ``--dir`` from above, it takes the following arguments:

- ``--lines``, Specify the maximum number of lines to print from the current end of the log file (defaults to 100)
- ``--follow`` (``-f``), Whether or not to continue following the log (press ctrl+c to stop following)

Examples
--------

**Instead of docker-sync-stack start**

The way ``docker-sync-stack start`` used to operate was to begin to sync the container(s) specified in the ``docker-sync.yml`` file, and then begin a ``docker-compose up``. The simplest way to replace this command is to use:

.. code-block:: shell

    docker-sync-daemon start
    docker-compose up

This will start your sync in the background, and then start all services defined in your docker-compose file in the foreground. This means that your sync continues in the background, even if you exit your ``docker-compose`` session(s). You can then stop that background sync with:


.. code-block:: shell

    docker-sync-daemon stop

This will show the logs for the daemon started above

.. code-block:: shell

    docker-sync-daemon logs

**Running commands before starting the docker-compose services**

By having the sync run in the background, you can then use a single shell session to ensure that the sync is running, and then run a few commands before starting all your services. You may wish to do this if you would like to use volumes to speed up rebuilds for node modules or gem bundles - as volumes are not available while building the image, but are when building the container.

.. code-block:: shell

    docker-sync-daemon start
    docker-compose run --rm $service yarn install
    docker-compose up -d

This will ensure that your sync containers are up and available so that commands utilizing the docker-compose file don't fail for not finding those containers. It will then run all services in the background.

Notes
-----

**New directory**

This will now create a ``.docker-sync`` directory alongside wherever you invoke the command (if you're asking it to run in the background). You will likely want to add this directory to your ``.gitignore`` file (or equivalent). You can, of course, use the ``--dir`` option to specify an alternate directory to save these files, but be sure to pass the same argument to ``stop``, and to use it consistently, or you may end up with multiple sync's running in the background...

**Invoking with the --config option**

I imagine most users will be invoking ``docker-sync`` without specifying an alternate path to the config file, but it's worth mentioning that if that's your current setup, you should also consider using the ``app_name`` option or the ``dir`` option to ensure that your ``pid`` file won't conflict with other invocations of docker-sync - otherwise you'll get a message saying that it's already running.
