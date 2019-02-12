Alternatives
============

This is a list of alternatives grouped by technology. Feel free to add the missing ones.

Docker native
-------------

Transparent, consistent, dual-sided (host -> container, container -> host) synchronization. Performance is here a trade-off for consistency. Can be 2-100 times slower than nfs and even more as compared with rsync.

- docker-toolbox_: virtualBox / fusion VM (horribly slow)
- `docker for mac`_: uses osxfs_. See osxfs-caching_ for optimization ideas. As of October 2017, they aren't proven to be effective yet.

.. _docker-toolbox: https://www.docker.com/products/docker-toolbox
.. _docker for mac: https://docs.docker.com/docker-for-mac/
.. _osxfs: https://docs.docker.com/docker-for-mac/osxfs/
.. _osxfs-caching: https://docs.docker.com/docker-for-mac/osxfs-caching/

OSXFS + unison
--------------

Dedicated container mounts a local directory via osxfs and runs Unison to synchronize this mount with a Docker volume.
- docker-magic-sync_
- docker-sync_ implements osxfs+unison-based sync when 'native_osx' is used as a strategy, being the default since 0.4.x. We use a special technique to achieve better performance, we sync with osxfs but the container still runs at native speed, let's call it decoupled sync.

.. _docker-magic-sync: https://github.com/mickaelperrin/docker-magic-sync

Unison
------

Unison runs both on the host and in a Docker container and synchronizes the macOS directory with a Docker container with Unison. **osxfs + unison** is a preferred alternative, because it's simpler and more reliable (bad FSEvents performance).

- docker-sync_ - unison can be used with docker-sync as well as a strategy, just set `sync_strategy: unison`
- Hodor_ (should be as fast as rsync?)

.. tip::

    You can choose to use Unison with docker-sync by adding sync_strategy: 'unison' to a sync-point too

.. _Hodor: https://github.com/gansbrest/hodor

Rsync
-----

Performance: Exactly the performance you would have without shares. Downside: **one-way sync**.

- docker-sync_ - rsync can be used with docker-sync as well as a strategy, just set `sync_strategy: rsync`
- docker-dev-osx_ (rsync, vbox only) - Hint: If you are happy with docker-machine and virtual box, this is a pretty solid alternative. It has been there for ages and is most probably pretty advanced. For me, it was no choice, since neither i want to stick to VBox nor it has support for docker-for-mac

.. _docker-dev-osx: https://github.com/brikis98/docker-osx-dev

NFS
---
Performance: In general, at least 3 times slower than **rsync**, often even more.

- Dinghy_ (docker-machine only, no docker for mac)
- DLite_ (docker-machine only, no docker for mac)
- Dusty_ (docker-machine only, no docker for mac)

.. _Dinghy: https://github.com/codekitchen/dinghy
.. _DLite: https://github.com/nlf/dlite
.. _Dusty: http://dusty.gc.com/

.. _docker-sync: https://docker-sync.io
