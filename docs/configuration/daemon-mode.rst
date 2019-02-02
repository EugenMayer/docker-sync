Daemon Mode
===========

Docker-sync in daemon mode
--------------------------

Beginning with version **0.4.0** Daemon mode is now the default, just use ``docker-sync start``. ``docker-sync-daemon`` is deprecated.

-----

Beginning with version **0.2.0**, docker-sync has the ability to run in a daemonized (background) mode.

In general you now run `docker-sync-daemon` to start in demonised mode, type ``docker-sync-daemon <enter>`` to see all options

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
