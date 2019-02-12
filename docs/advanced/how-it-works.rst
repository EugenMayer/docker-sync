************
How it works
************

Architecture
============

On the host, a thor based ruby task is started, this starts:

    - Every sync will start an own docker-container with a rsync/unison-daemon watching for connections.
    - The data gets pre-synced on sync-start
    - A fswatch cli-task gets setup, to run rsync/unison on each file-change in the source-folder you defined

Done. No magic. But its roadrunner fast! And it has no pre-conditions on your actual stack.

----

.. _native_osx in depth:

native_osx in depth
===================

Under The Hood
--------------

First, take a look at this diagram:

.. image:: /_static/native_osx.png
  :alt: DockerSync native_osx strategy overview

There are some important keypoints to notice here:

1. We use OSXFS to mount your local host folder into the sync-container.
2. We do not mount this in the app-container directly, since this would lead to `infamously horrible performance`_.
3. Instead of directly mounting ``/host_sync`` in the app-container we setup a **2-way-sync** inside the sync-container using Unison_. This ensures that the actual READ/WRITE performance on the ``/app_sync`` folder is native-speed fast.
4. This makes all operations on ``/app_sync`` be asynchronous with ``/host_sync``, since writing and reading on ``/app_sync`` does not rely on any OSXFS operation directly, **but shortly delayed and asynchronous**.
5. We mount ``/app_sync`` to your app_container - since this happens in hyperkit, it's a **Docker LINUX-based** native  mount, thus running at native-speed.
6. Your application now runs like there was no sync at all.

.. _infamously horrible performance: https://docs.docker.com/docker-for-mac/osxfs/#performance-issues-solutions-and-roadmap
.. _Unison: http://www.cis.upenn.edu/~bcpierce/unison/

FAQ
---

Why use OSXFS in the first place (instead of the ``unison`` strategy) to sync from the host to the sync-container
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

There are several reasons, one of the most important being the performance. Since MacOS/OSX has very bad filesystem events support on HFS/APFS, watching the file-system for changes using ``unox`` or ``fswatch`` was causing a heavy CPU load. This CPU load is very significant, even on modern high-end CPUs (like a i7 4770k / 3.5GHz).

The second issue was dependencies. With native_osx you do not need to install anything on your host OS except the docker-sync gem. So no need to compile unox or install unison manually, deploy with brew and fail along the way - just keeping you system clean.

Is this strategy absolutely bullet proof?
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

No, it is not. But it has been pretty battle proven already - the main issue is https://github.com/EugenMayer/docker-sync/issues/410 - so sometimes OSXFS just stops triggering FS events in Hyperkit, thus in the sync-container. This leads to an issue with our sync, since the ``unison`` daemon inside the app-sync  container relies on those events to sync the changes (it does not have the ability to poll, which would be disastrous performance-wise, anyway).

Advanced Monitoring for ``native_osx``
--------------------------------------

Background
^^^^^^^^^^

Monit_ is a utility which can be used to monitor the health of the ``unison`` process which runs in the container for the ``native_osx`` strategy. If it detects that ``unison`` is unhealthy, Monit automatically restarts ``unison``. This improves the stability of the ``native_osx`` container in cases where the ``unison`` process is misbehaving but does not necessarily crash. Currently, there is only one check for CPU usage implemented, but in the future more checks may be added, such as memory usage. It is currently turned off by default and can be turned on in the configuration:

https://github.com/EugenMayer/docker-sync/blob/master/example/docker-sync.yml#L120-L126

.. _Monit: https://mmonit.com/monit/

Monitoring CPU usage
^^^^^^^^^^^^^^^^^^^^

One instance which ``unison`` has been seen to misbehave is when quickly creating and deleting a file while it is processing it. ``unison`` may hang, using a high amount of cpu time: https://github.com/EugenMayer/docker-sync/issues/497. ``monit`` detects this high cpu usage (>50%) and automatically restarts ``unison`` to recover it. By default this happens within 10 seconds, but the tolerance can be configured in case there are normal spikes in cpu usage during successful syncs.
