****************************************************
Advanced troubleshooting for ``native_osx`` strategy
****************************************************

.. note::

    This document is a work in progress. Each time you encounter the scenario below, please revisit this document and `report any new findings`_.

.. _report any new findings: https://github.com/EugenMayer/docker-sync/issues/410

The osx_native sync strategy is the fastest sync strategy for docker-sync under Docker4Mac. Unfortunately a recurring issue has emerged where the `sync strategy stops functioning`_. This page is to guide you on how to debug this situation to provide information so that it can be solved.

.. _sync strategy stops functioning: https://github.com/EugenMayer/docker-sync/issues/410

Step 1 - Prepare: Identify the docker-sync container involved
=============================================================

First, open your docker-sync.yml file and find the sync that has to do with the code that appears to be failing to sync.

For example, if you have two docker-sync mounts like so:

.. code-block:: yaml

    syncs:
      default-sync:
        src: './default-data/'
      fullexample-sync:
        src: './data1'

And your file that is not updating is under ``default-data``, then your sync name is ``default-sync``.

Run this in your terminal (substitute in your sync name) for use in the remaining steps: ``DEBUG_DOCKER_SYNC='default-sync'``

Step 2 - Prepare: A file path to check
======================================

Next we're going to assign a file path to a variable for use in the following steps.

1. Change into your sync directory (in the example ``cd default-data/``)
2. Prepare the relative path to your file that does not appear to be updating upon save, example ``some-dir/another-dir/my-file.ext``
3. Run the following command with your path substituted in: ``DEBUG_DOCKER_FILE='some-dir/another-dir/my-file.ext'``

Step 3 - Reproduction: Verify your host mount works (host_sync)
===============================================================

Run this to verify that your file changes have been synced by OSXFS to the sync-container

.. code-block:: shell

    diff -q "$DEBUG_DOCKER_FILE" <(docker exec "$DEBUG_DOCKER_SYNC" cat "/host_sync/$DEBUG_DOCKER_FILE")

Usually this should never get broken at all, if it does, you see one of the following messages, the so called host_sync is broken:

.. code-block:: shell

    Files some-dir/another-dir/my-file.ext and /dev/fd/63 differ
    diff: some-dir/another-dir/my-file.ext: No such file or directory

Step 4 - Reproduction: Verify your changes have been sync by unison (app_sync)
==============================================================================

Run this to verify that the changes have been sync from host_sync to app_sync on the container (using unison)

.. code-block:: shell

    diff -q "$DEBUG_DOCKER_FILE" <(docker exec "$DEBUG_DOCKER_SYNC" cat "/app_sync/$DEBUG_DOCKER_FILE")

If you see a message one of the messages, this so called app_sync is broken:

.. code-block:: shell

    Files some-dir/another-dir/my-file.ext and /dev/fd/63 differ
    diff: some-dir/another-dir/my-file.ext: No such file or directory

*If you do not see a message like one of these, then the issue you are encountering is not related to a sync failure and is probably something like caching or some other issue in your application stack, not docker-sync.*

Step 5 - Reproduction: Unison log
=================================

If one of the upper errors occurred, please include the unison logs:

.. code-block:: shell

    docker exec "$DEBUG_DOCKER_SYNC" tail -n70 /tmp/unison.log

And paste those on Hastebin_ and include the link in your report

Step 6 - Reproduction: Ensure you have no conflicts
===================================================

Put that into your problematic sync container docker-sync.yml config:

.. code-block:: shell

    sync_args: "-copyonconflict -debug verbose"

Restart the stack

.. code-block:: shell

    docker-sync-stack clean
    docker-sync-stack start

Now do the file test above and see, if next to the file, in host_sync or app_sync a conflict file is created, its called something like conflict

Also then include the log

.. code-block:: shell

    docker exec "$DEBUG_DOCKER_SYNC" tail -n70 /tmp/unison.log

And paste those on Hastebin_ and include the link in your report

.. _Hastebin: https://hastebin.com

Step 7 - Report the issue
=========================

If the issue still persists, post the results from the above steps in a new Github issue (see an example at `issue #410`)_.

.. _issue #410: https://github.com/EugenMayer/docker-sync/issues/410
