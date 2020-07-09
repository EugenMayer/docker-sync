*************
Configuration
*************

.. caution::

    When you change anything in your docker-sync.yml be sure to run docker-sync clean and docker-sync start right after it. Just running docker-sync start or stop will not recreate the container and your changes will have no effect!

docker-sync.yml
===============

The file docker-sync.yml should be placed in the top-level folder of your project, so docker-sync can find it. The configuration will be searched from the point you run docker-sync from, traversing up the path tree

In there, you usually configure one ( or more ) sync points. Be sure to decide which sync-strategy you want to chose, see :doc:`../advanced/sync-strategies`.

Below are all the available options, simple examples can be found in the docker-sync-boilerplate_.

.. important::

    Be sure to use a sync-name which is unique, since it will be a container name. Do not use your app name, but rather app-sync.

.. _docker-sync-boilerplate: https://github.com/EugenMayer/docker-sync-boilerplate


Simple configuration file
-------------------------

.. code-block:: yaml

    version: "2"
    options:
      verbose: true
    syncs:
      appcode-native-osx-sync:
        src: './app'
        sync_excludes: ['ignored_folder', '.ignored_dot_folder']


General options
---------------
Configuration options below the top-level ``options`` key.


cli_mode
^^^^^^^^
Defines how the sync will be invoked on the command line.
Mostly depending if your are using docker-sync solo,
scaffolded or in development (thor).

Optional.

default:
  ``auto``

possible values:
  - ``docker-sync``
  - ``thor``
  - ``auto``


compose-file-path
^^^^^^^^^^^^^^^^^
If you like, you can set a custom location (path) of your compose file like
``~/app/compose.yml``.

You can also use this as an array to define several compose files to include.
Order is important!

Optional.

default:
  ``docker-compose.yml``

possible values:
  - A single file name
  - An array of file names


compose-dev-file-path
^^^^^^^^^^^^^^^^^^^^^
If you like, you can set a custom location (path) of your compose file.
Do not set it, if you do not want to use it at all.

If its there, it gets used. If you name it explicitly, it HAS to exist.

HINT: you can also use this as an array to define several compose files to include.
Order is important!

Optional.

default:
  ``docker-compose-dev.yml``

possible values:
  - A single file name
  - An array of file names


max_attempt
^^^^^^^^^^^
Maximum number of attempts for unison waiting for the success exit status.

Each attempt means 1-second sleep.
Only used in unison.

Optional.

default:
  ``5``


project_root
^^^^^^^^^^^^
Root directory to be used when transforming sync src into absolute path.

Optional

default:
  ``pwd``

possible values:
  - ``pwd`` (current working directory)
  - ``config_path`` (the directory where docker-sync.yml is found)


<sync_strategy>_image
^^^^^^^^^^^^^^^^^^^^^
The image to use for the rsync container.

Do not change this until you exactly know, what you are doing

Replace ``<sync_strategy>`` with either ``rsync``, ``unison``, ``native_osx``
to set a custom image for all sync of this type.


verbose
^^^^^^^
Activate this if you need to debug something.

IMPORTANT: do not run stable with this, it creates a memory leak.
Turn off verbose when you are done testing

Optional.

default:
  ``false``

possible values:
  - ``true``
  - ``false``


Synchronization options
-----------------------
Configuration options for a synchronzation definition below the top-level ``syncs``.


host_disk_mount_mode
^^^^^^^^^^^^^^^^^^^^
See https://docs.docker.com/docker-for-mac/osxfs-caching/#cached

possible values:
  - ``cached``
  - ``consistent``
  - ``default``
  - ``delegated``


monit_enable
^^^^^^^^^^^^
Monit can be used to monitor the health of unison in the ``native_osx`` strategy
and can restart unison if it detects a problem.

Optional.

default:
  ``false``

possible values:
  - ``true``
  - ``false``


monit_high_cpu_cycles
^^^^^^^^^^^^^^^^^^^^^
Use this to change how many consecutive times high cpu usage must be observed
before unison is restarted.

Optional.

default:
  2 FIXME

possible values:
  Integer numbers


monit_interval
^^^^^^^^^^^^^^
Use this to change how many seconds between each monit check (cycle).

Optional.

default:
  none

possible values:
  Number of seconds (``5``)


notify_terminal
^^^^^^^^^^^^^^^
Enable terminal_notifier.
On every sync sends a Terminal Notification regarding files being synced.
(Mac Only).

Good thing in case you are developing and want to know exactly when your
changes took effect.
Be aware in case of unison this only gives you a notification on the initial sync,
not the syncs after changes.

default:
  ``false``

possible values:
  - ``true``
  - ``false``


src
^^^
Which folder to watch / sync from - you can use tilde ``~``, it will get expanded.

The contents of this directory will be synchronized to the Docker volume
with the name of this sync entry (``shortexample-sync`` here).

Be aware that the trailing slash makes a difference.
If you add them, only the inner parts of the folder gets synced,
otherwise the parent folder will be synced as top-level folder.

Mandatory.

default:
  No default value

possible values:
  A directory name


sync_args
^^^^^^^^^
Use this to switch to rsync verbose mode

Optional.

default:
  empty

possible values:
  Any option accepted by ``rsync``, e.g. ``-v`` or ``-L``.


sync_excludes
^^^^^^^^^^^^^
A list of excludes. These patterns will not be synced.

See
http://www.cis.upenn.edu/~bcpierce/unison/download/releases/stable/unison-manual.html#ignore
for the possible syntax and see ``sync_excludes_type`` below.

Optional.

default:
  empty

possible values:
  Array of file and directory names


Example::

  sync_excludes: ['Gemfile.lock', 'Gemfile', 'config.rb', '.sass-cache', 'sass', 'sass-cache', 'composer.json' , 'bower.json', 'package.json', 'Gruntfile*', 'bower_components', 'node_modules', '.gitignore', '.git', '*.coffee', '*.scss', '*.sass']

List example::

  sync_excludes:
    - 'Gemfile.lock'
    - 'Gemfile'
    - 'config.rb'
    - '.sass-cache'


sync_excludes_type
^^^^^^^^^^^^^^^^^^
Use this to change the ``sync_exclude`` syntax.

For more information see
http://www.cis.upenn.edu/~bcpierce/unison/download/releases/stable/unison-manual.html#pathspec

Optional.

default:
  ``Name``

possible values:
  - ``Path``: you match the exact path ( nesting problem )
  - ``Name``: If a file or a folder does match this string ( solves nesting problem )
  - ``Regex``: Define a regular expression
  - ``none``: You can define a type for each sync exclude, so sync_excludes::

      ['Name .git', 'Path Gemlock']


sync_groupid
^^^^^^^^^^^^
Usually if you map groups you want to set the group id of your application
container here.

This does not user groupmap but rather configures the server to map.
This is only available for unison/rsync, not for d4m/native (default) strategies.

Optional.

possible values:
  Container group IDs (``6000``)


sync_host_ip
^^^^^^^^^^^^
When a port of a container is exposed, on which IP does it get exposed.
Localhost for docker for mac, something else for docker-machine.

default:
  ``auto``

possible values:
  - ``auto``:your docker-machine/docker host ip will be detected automatically.
  - IP address: If you set this to a concrete IP, this OP will be enforced


sync_host_port
^^^^^^^^^^^^^^
Should be a unique port this sync instance uses on the host to offer
the rsync service on.

Do not use this for unison - not needed there.

Mandatory for ``rsync``.

default:
  No default value


sync_prefer
^^^^^^^^^^^
Defines how sync conflicts should be handled.

Optional.

default:
  ``default``

possible values:
  - ``default``: It will prefer the source
  - ``copyonconflict``: On conflict, pick the one from the host and copy the
    conflicted file for backup


sync_strategy
^^^^^^^^^^^^^
Operating system aware sync strategy.

Remove this option to use the default strategy per OS.

See :doc:`../advanced/sync-strategies`.

Optional.

default:
  - ``native_osx`` under MacOS (except with docker-machine which use unison),
  - ``native_linux`` docker volume under linux

possible values:
  - ``native_linux`` (Linux)
  - ``native_osx`` (OSX)
  - ``unison`` (Linux, OSX, Windows)
  - ``rsync`` (OSX)


sync_userid
^^^^^^^^^^^
Usually if you map users you want to set the user id of your
application container here.

This does not user groupmap but rather configures the server to map.

Optional.

possible values:
  Container user IDs (``5000``)


watch_args
^^^^^^^^^^
Use this to switch to ``fswatch`` verbose mode

Optional.

default:
  Empty

possible values:
  Every ``fswatch`` option like ``-v``


watch_excludes
^^^^^^^^^^^^^^
A list of regular expressions to exclude from the fswatch - see fswatch docs
for details.

IMPORTANT: this is not supported by ``native_osx``.

default:
  empty

possible values:
  directory and file names, ``*`` are supported

Example::

  watch_excludes: ['.*/.git', '.*/node_modules', '.gitignore']


-----

.. _docker-compose-yml:

docker-compose.yml
==================

You should split your docker-compose configuration for production and development (as usual). The production stack (docker-compose.yml) does not need any changes and would look like this (and is portable, no docker-sync adjustments).

.. code-block:: yaml

    version: "2"
    services:
      someapp:
        image: alpine
        container_name: 'fullexample_app'
        command: ['watch', '-n1', 'cat /var/www/somefile.txt']
      otherapp:
        image: alpine
        container_name: 'simpleexample_app'
        command: ['watch', '-n1', 'cat /app/code/somefile.txt']

docker-compose-dev.yml
======================

The docker-compose-dev.yml ( it needs to be called that way, look like this ) will override this and looks like this.

.. code-block:: yaml

    version: "2"
    services:
      someapp:
        volumes:
          - fullexample-sync:/var/www:nocopy # nocopy is important
      otherapp:
        # thats the important thing
        volumes:
          - simpleexample-sync:/app/code:nocopy #  nocopy is important

    volumes:
      fullexample-sync:
        external: true
      simpleexample-sync:
        external: true

.. tip::

    Do check that you use nocopy, see below for the explanation

So the docker-compose-dev.yml includes the volume mounts and definitions - your production docker-compose.yml will be overlaid by this when starting the stack with

.. code-block:: shell

    docker-sync-stack start

This effectively does this in docker-compose terms

.. code-block:: shell

    docker-compose -f docker-compose.yml -f docker-compose-dev.yml up

Portable docker-compose.yml
---------------------------

Most of you do not want to inject docker-sync specific things into the production ``docker-compose.yml`` to keep it portable. There is a good way to achieve this very cleanly based on docker-compose overrides.

1. Create a ``docker-compose.yml`` (you might already have that one) - that is your production file. Do not change anything here, just keep it the way you would run your production environment.
2. Create a ``docker-compose-dev.yml`` - this is where you put your overrides into. You will add the external volume and the mount here, also adding other development ENV variables you might need anyway

Start your compose using:

.. code-block:: shell

    docker-compose -f docker-compose.yml -f docker-compose-dev.yml up

If you only have macOS- and Linux-based development environments, create ``docker-compose-Linux.yml`` and ``docker-compose-Darwin.yml`` to put your OS-specific overrides into. Then you may start up your dev environment as:

.. code-block:: shell

    docker-compose -f docker-compose.yml -f docker-compose-$(uname -s).yml up

You can simplify this command by creating an appropriate `shell alias`_ or a Makefile_. There is also a `feature undergo`_ to let ``docker-sync-stack`` support this out of the box, by simply calling:

.. code-block:: shell

    docker-sync-stack start

A good example for this is a part of the `boilerplate project`_.

.. _shell alias: https://en.wikipedia.org/wiki/Alias_(command)
.. _Makefile: https://en.wikipedia.org/wiki/Makefile
.. _feature undergo: https://github.com/EugenMayer/docker-sync/issues/41
.. _boilerplate project: https://github.com/EugenMayer/docker-sync-boilerplate


.. _why-nocopy-important:

Why :nocopy is important?
=========================

In case the folder we mount to has been declared as a VOLUME during image build, its content will be merged with the name volume we mount from the host - and thats not what we want. So with nocopy we ignore the contents which have been on the initial volume / image and do enforce the content from our host on the initial wiring


.. code-block:: yaml

    version: "2"
    services:
      someapp:
        volumes:
          - fullexample-sync:/var/www

to

.. code-block:: yaml

    version: "2"
    services:
      someapp:
        volumes:
          - fullexample-sync:/var/www:nocopy

.. _environment-variables:

Environment variables support
=============================

Docker-sync supports the use of environment variables from version 0.2.0.

The support is added via implementation of https://github.com/bkeepers/dotenv.

You can set your environment variables by creating a .env file at the root of your project (or form where you will be running the docker-sync commands).

The environment variables work the same as they do with docker-compose.

This allows for simplifying your setup, as you are now able to change the project dependent values instead of modifying yaml files for each project.


.. tip::

    You can change the default file using ``DOCKER_SYNC_ENV_FILE``, e.g. if .env is already used for something else, you could use ``.docker-sync-env`` by setting export ``DOCKER_SYNC_ENV_FILE=.docker-sync-env``


.. code-block:: shell

    # contents of your .env file
    WEB_ROOT=/Users/me/Development/web
    API_ROOT=./dir

The environment variables will be picked up by docker-compose

.. code-block:: yaml

    services:
      api:
        build: ${API_ROOT}

and by docker-sync as well.

.. code-block:: yaml

    # WEB_ROOT is /Users/me/Development/web
    syncs:
      web-rsync:
        src: "${WEB_ROOT}"

For a detailed example take a look at https://github.com/EugenMayer/docker-sync-boilerplate/tree/master/dynamic-configuration-dotnev.
