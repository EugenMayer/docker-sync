Portable docker-compose.yml
===========================

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
