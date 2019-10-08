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

References
----------

.. caution::

    This is a configuration reference. **Do not use all options at once, they do not make sense!** Or copy them as your starting point, rather use the docker-sync-boilerplate and then cherry pick the options you need.

.. code-block:: yaml

    options:
      # default: docker-compose.yml if you like, you can set a custom location (path) of your compose file like ~/app/compose.yml
      # HINT: you can also use this as an array to define several compose files to include. Order is important!
      compose-file-path: 'docker-compose.yml'

      # optional, default: docker-compose-dev.yml if you like, you can set a custom location (path) of your compose file. Do not set it, if you do not want to use it at all

      # if its there, it gets used, if you name it explicitly, it HAS to exist
      # HINT: you can also use this as an array to define several compose files to include. Order is important!
      compose-dev-file-path: 'docker-compose-dev.yml'

      # optional, activate this if you need to debug something, default is false
      # IMPORTANT: do not run stable with this, it creates a memory leak, turn off verbose when you are done testing
      verbose: false

      # ADVANCED: the image to use for the rsync container. Do not change this until you exactly know, what you are doing
       # replace <sync_strategy> with either rsync, unison, native_osx to set a custom image for all sync of this type
       # do not do that if you really do not need that!
      <sync_strategy>_image: 'yourcustomimage'

      # optional, default auto, can be docker-sync, thor or auto and defines how the sync will be invoked on the cli. Mostly depending if your are using docker-sync solo, scaffolded or in development ( thor )
      cli_mode: 'auto'
      # optional, maximum number of attempts for unison waiting for the success exit status. The default is 5 attempts (1-second sleep for each attempt). Only used in unison.
      max_attempt: 5

      # optional, default: pwd, root directory to be used when transforming sync src into absolute path, accepted values: pwd (current working directory), config_path (the directory where docker-sync.yml is found)
      project_root: 'pwd'

    syncs:
      default-sync:
        # os aware sync strategy, defaults to native_osx under MacOS (except with docker-machine which use unison), and native docker volume under linux
        # remove this option to use the default strategy per os or set a specific one
        sync_strategy: 'native_osx'
        # which folder to watch / sync from - you can use tilde, it will get expanded.
        # the contents of this directory will be synchronized to the Docker volume with the name of this sync entry ('default-sync' here)
        src: './default-data/'

        host_disk_mount_mode: 'cached' # see https://docs.docker.com/docker-for-mac/osxfs-caching/#cached
        # other unison options can also be specified here, which will be used when run under osx,
        # and ignored when run under linux

      # IMPORTANT: this name must be unique and should NOT match your real application container name!
      fullexample-sync:
        # enable terminal_notifier. On every sync sends a Terminal Notification regarding files being synced. ( Mac Only ).
        # good thing in case you are developing and want to know exactly when your changes took effect.
        # be aware in case of unison this only gives you a notification on the initial sync, not the syncs after changes.
        notify_terminal: true

        # which folder to watch / sync from - you can use tilde (~), it will get expanded. Be aware that the trailing slash makes a difference
        # if you add them, only the inner parts of the folder gets synced, otherwise the parent folder will be synced as top-level folder
        src: './data1'

        # when a port of a container is exposed, on which IP does it get exposed. Localhost for docker for mac, something else for docker-machine
        # default is 'auto', which means, your docker-machine/docker host ip will be detected automatically. If you set this to a concrete IP, this ip will be enforced
        sync_host_ip: 'auto'

        # should be a unique port this sync instance uses on the host to offer the rsync service on
        # do not use this for unison - not needed there
        # sync_host_port: 10871

        # optional, a list of excludes. These patterns will not be synced
        # see http://www.cis.upenn.edu/~bcpierce/unison/download/releases/stable/unison-manual.html#ignore for the possible syntax and see sync_excludes_type below
        sync_excludes: ['Gemfile.lock', 'Gemfile', 'config.rb', '.sass-cache', 'sass', 'sass-cache', 'composer.json' , 'bower.json', 'package.json', 'Gruntfile*', 'bower_components', 'node_modules', '.gitignore', '.git', '*.coffee', '*.scss', '*.sass']

        # use this to change the exclude syntax.
        # Path: you match the exact path ( nesting problem )
        # Name: If a file or a folder does match this string ( solves nesting problem )
        # Regex: Define a regular expression
        # none: You can define a type for each sync exclude, so sync_excludes: ['Name .git', 'Path Gemlock']
        #
        # for more see http://www.cis.upenn.edu/~bcpierce/unison/download/releases/stable/unison-manual.html#pathspec
        sync_excludes_type: 'Name'

        # optional: use this to switch to rsync verbose mode
        sync_args: '-v'

        # optional, default can be either rsync or unison See Strategies in the wiki for explanation
        sync_strategy: 'unison'

        # this does not user groupmap but rather configures the server to map
        # optional: usually if you map users you want to set the user id of your application container here
        sync_userid: '5000'

        # optional: usually if you map groups you want to set the group id of your application container here
        # this does not user groupmap but rather configures the server to map
        # this is only available for unison/rsync, not for d4m/native (default) strategies
        sync_groupid: '6000'
        
        # defines how sync-conflicts should be handled. With default it will prefer the source with --copyonconflict
        # so on conflict, pick the one from the host and copy the conflicted file for backup
        sync_prefer: 'default'

        # optional, a list of regular expressions to exclude from the fswatch - see fswatch docs for details
        # IMPORTANT: this is not supported by native_osx
        watch_excludes: ['.*/.git', '.*/node_modules', '.*/bower_components', '.*/sass-cache', '.*/.sass-cache', '.*/.sass-cache', '.coffee', '.scss', '.sass', '.gitignore']

        # optional: use this to switch to fswatch verbose mode
        watch_args: '-v'

        # monit can be used to monitor the health of unison in the native_osx strategy and can restart unison if it detects a problem
        # optional: use this to switch monit monitoring on
        monit_enable: false

        # optional: use this to change how many seconds between each monit check (cycle)
        monit_interval: 5

        # optional: use this to change how many consecutive times high cpu usage must be observed before unison is restarted
        monit_high_cpu_cycles: 2

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
