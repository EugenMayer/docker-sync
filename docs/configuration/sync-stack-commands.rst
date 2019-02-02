Sync stack commands
===================

docker-sync-stack
-----------------

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
