Dynamic Configuration
=====================

Environment variables support
-----------------------------

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
