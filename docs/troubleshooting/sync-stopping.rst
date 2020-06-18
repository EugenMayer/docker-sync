*************
Sync stopping
*************

Npm / webpack / gulp based projects
===================================

Npm, webpack, gulp, and any other tooling that watches, deletes and/or creates a lot of files may cause sync to stop.

In most cases, this has nothing to do with docker-sync at all, but with OSXFS getting stuck in the FS event queue, which then also stops events for unison in our docker image (linux, so inode events) and thus breaks syncing.

- Run ``npm i``, ``composer install``, and the likes **before** ``docker-sync start``. This way we avoid tracking unnecessary FS events prior to start.

- Sync only necessary folders, e.g. ``src/`` folders. Restructure your project layout if needed.


Other reported solutions
========================

1. Run ``docker-sync stop && docker-sync start``
2. Run ``docker-sync stop && docker-sync clean && docker-sync start``
3. Manually going to the unison docker container and executing ``kill -1 [PID]`` on the unison process (`suggested by @grigoryosifov`_)
4. Sometimes, the OSXFS itself gets stuck. Docker for Mac restart maybe the only option. Sometimes, an OS restart is the only option.

.. _suggested by @grigoryosifov: https://github.com/EugenMayer/docker-sync/issues/646#issuecomment-466991460
