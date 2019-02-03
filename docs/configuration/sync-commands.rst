Sync commands
=============

Generally you can just list all the help in the cli by

.. code-block:: shell

    docker-sync help

Start
-----

.. code-block:: shell

    docker-sync start

.. tip::

    Check :doc:`../configuration/sync-stack-commands` on how ``docker-sync-stack start`` works to start sync / compose at the same time.

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
