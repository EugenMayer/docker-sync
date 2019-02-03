Sync strategies
===============

The sync strategies depend on the OS, so not all strategies are available on all operating system

- OSX: native_osx, unison, rsync
- Windows: unison
- Linux: native_linux, unison

----

.. _strategies-native-osx:

native_osx (OSX)
----------------

.. image:: /_static/native_osx.png
  :alt: DockerSync native_osx strategy overview

For advanced understanding, please read :ref:`native_osx in depth`.

Native-OSX is a combination of two concepts, `OSXFS only`_ and Unison together. We use OSX to sync the file-system into a sync-container to /host_sync. In that sync container we sync from /host_sync to /app_sync using Unison. /app_sync is exposed as a named volume mount and consumed in the app. You ask yourself, why? Its fairly simple.

By having this extra layer of unison on linux, we detach the actual write/read performance of your application from the actual OSXFS performance - running at native speed. Still, we using OSXFS, a about up to 1 second delayed, to synchronize changes both ways. So we have a 2-way sync.

What is different to plain Unison you might ask. The first big issue with Unison is, how bad it performs under OSX due to the bad FS-Events of OSX, implemented in macfsevents and alikes. It uses a lot of CPU for watching files, it can lose some events and miss a sync - but also, it adds extra dependencies on the OSX hosts.

All that is eliminated by native_osx - we use Unison in the Linux container, where it performs great due to inotify-event based watchers.

Pros
 - Far more reliable due to a low-level implementation of the sync using `OSXFS only`_
 - Uses far less CPU to sync files from the host to the sync container - will handle a lot more files
 - No daemon to run, control, restart and sync on the OSX host. Makes sleep/hibernate/reboot much more robust
 - No dependencies on the OSX-Host at all
 - A lot easier installation since we just need ``gem install docker-sync`` and that on runs under system ruby. Anything else is in containers
 - It performs at native speed
 - It will be much easier to support Windows this way

Cons
 - Initial start can take longer as on unison, since the first sync is more expensive. But this is one time only
 - It works under Docker for Mac only - missing file system events under vbox/fusion. See `native_osx does not work with docker-machine vbox / fusion`_

.. _OSXFS only: https://github.com/EugenMayer/docker-sync/issues/346
.. _native_osx does not work with docker-machine vbox / fusion: https://github.com/EugenMayer/docker-sync/issues/346

----

unison (OSX/Windows/Linux)
--------------------------

This strategy has the biggest drive to become the new default player out of the current technologies. It seems to work very well with huge codebases too. It generally is build to handle 2 way sync, so syncs back changes from the container to the host.

Pros
 - Offers 2 way sync (please see unison-dualside why this is misleading here)
 - Still very effective and works for huge projects
 - Native speed in for the application

Cons
 - Can be unreliable with huge file counts (> 30.000) and bad hardware (events gets stuck)
 - The daemon on OSX needs extra care for sleep/hibernate.
 - Extra dependencies we need on OSX, in need to install unison and unox natively - brew dependencies

**Initial startup delays with unison**

On initial start, Unison sync needs to build a catalog of the files in the synced folder before sync begins. As a result, when syncing folders with large numbers of relatively large files (for example, 40k+ files occupying 4G of space) using unison, you may see a significant delay (even 20+ minutes) between the initial ``ok  Starting unison`` message and the ``ok  Synced`` message. This is not a bug. Performance in these situations can be improved by moving directories with a large number of files into a separate ``rsync`` strategy sync volume, and using unison only on directories where two-way sync is necessary.

----

rsync (OSX)
-----------

This strategy is probably the simplest one and probably the most robust one for now, while it has some limitations. rsync-syncs are known to be pretty fast, also working very efficient on huge codebases - no need to be scared of 20k files. rsync will easily rsync the changes ( diff ) very fast.

Pros
 - Fast re-syncing huge codebases - sync diffs (faster then unison? proof?)
 - Well tested and known to be robust
 - Best handling of user-permission handling ( mapped into proper users in the app container )

Cons
 - Implements a one way sync only, means only changes of your codebase on the host are transferred to the app-container. Changes of the app-container are not synced back at all
 - Deleting files on the host does yet not delete them on the container, since we do not use --delete, see `#347`_

Example: On the docker-sync-boilerplate_

.. _#347: https://github.com/EugenMayer/docker-sync/issues/37
.. _docker-sync-boilerplate: https://github.com/EugenMayer/docker-sync-boilerplate/tree/master/rsync

----

native_linux
------------

Native linux is actually no real implementation, it just wraps docker-sync around the plain native docker mounts which do work perfectly on linux. So there are no sync-containers, no strategies or what so ever. This strategy is mainly used just to have the whole team use docker-sync, even on linux, to have the same interface. If you use default sync_strategy in the docker-sync.yml, under Linux, native_linux is picked automatically

----

Sync Flags or Options
---------------------

You find the available options for each strategy in :doc:`../getting-started/configuration`.
