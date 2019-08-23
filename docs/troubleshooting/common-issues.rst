*******************
Other common issues
*******************

Incorrect mount location
========================

Docker-sync uses a named container/volume for synchronizing. There is a chance you may have a conflicting sync name. To verify this, run:

.. code-block:: shell

    docker container inspect --format '{{(index .Mounts 1).Source}}' "$DEBUG_DOCKER_SYNC"

If you do not see the path to your directory, this means your mount location is conflicting. To fix this issue:

1. Bring your containers down
2. Perform ``docker-sync clean``
3. Bring your containers back up again.
