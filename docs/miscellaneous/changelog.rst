Changelog
=========

.. attention::

    This is legacy/deprecated. Newer changelogs are now part of the releases. See https://github.com/EugenMayer/docker-sync/releases.

0.5.0
-----

.. note::

    This release has no breaking changes, so it is a drop-in-replacement for 0.4.6 without migration.

-----

Features/Improvements
 - Integrations tests - huge credits to @michaelbaudino
 - FreeBSD support
 - print sync time so you can see potential stalls earlier #431
 - be able to set max_attempt in global configuration #403
 - added support for d4m edge #478
 - added `diagram to explain how native_osx works`_ #465
 - upgraded terminal-notifier to 2.0.0 #486
 - upgraded docker-compose gem to 1.1 #486
 - upgraded thor to 0.20 #486

Bugfixes:
 - default ip detection fixed
 - fix several typos and docs #432 #409 #404 #396
 - fix exceptions thrown #406
 - unison mount destination #433
 - fix issues with spaces in folder / paths when using unison #426

Special thanks to @michaelbaudino who has done a incredible job

.. _diagram to explain how native_osx works: https://github.com/EugenMayer/docker-sync/blob/master/doc/native_osx.png

----

0.4.6
-----

Fixes:
 - Fixed Issue introduced with 0.4.5: #367

Nothing else - most probably the last 0.4.x release.

----

0.4.5
-----

See https://github.com/EugenMayer/docker-sync/milestone/22?closed=1 for the bugfixes

Windows and Linux support now got documented and the documentation has been made more cross-platform.

Mot probably last 0.4.x maintenance release - with 0.5.x a rewrite of the Config/Dependency/Env/Os handling is supercharged by @michaelbaudino. This will help improving the overall quality of the codebase and reduce the clusterfuck when we do cross-platform implementation / splits. Be tensed.

----

0.4.2
-----
 - Implement proper selective sync default: native_osx for d4m and unison for docker-machine, see https://github.com/EugenMayer/docker-sync/issues/350
 - When you run --foreground with native_osx you now see the unison logs running in the container, see https://github.com/EugenMayer/docker-sync/issues/341
 - Properly pull new unison:hostsync image to fix 0.4.0 bugs

----

0.4.1
-----
 - Fixing issue with sync_userid and native_osx
 - Fixing different new and old issues with native_osx and unison / installation and upgrade issues
 - More at https://github.com/EugenMayer/docker-sync/issues?q=is%3Aclosed+milestone%3A0.4.1

----

0.4.0
-----
 - **New Sync Strategy native_osx.** See :ref:`strategies-native-osx`
 - Daemon mode is now the default mode
 - No need for unison/unox by default when using native_osx
 - Better performance when using native_osx
 - Fixed auto-ip guessing
 - More at https://github.com/EugenMayer/docker-sync/milestone/17?closed=1

----

0.3.6
-----
 - **Finally removed any support of `dest` which has been deprecated since 0.2.x.**
 - Linux support: docker-sync can now also be used under Linux, were it does a fallback to native volume mounts automatically.
 - Introducing auto-guessing of the sync_host_ip for simultaneous usage of the same ``docker-sync.yml`` using d4m, docker-toolbox and others. Just set ``sync_host_ip: 'auto'``
 - Fixed spaces in ./src lead to issues with unison
 - Fixed various issues with the installation of 0.3.x
 - Fixed issues with the new configuration model
 - Overall making docker-sync more robust and verbose if things are not as intended
 - More at https://github.com/EugenMayer/docker-sync/milestone/16?closed=1

----

0.3.1 - 0.3.5
-------------
 - Bugfixes

----

0.3.0
-----
 - You can now chose the dotenv file to be used by docker-sync using setting DOCKER_SYNC_ENV_FILE
 - The configuration has been rewritten, huge thank you to @ignatiusreza for his effort. This was done to support better scaffolding ( inline configuration loading ), prepare linux support ( or windows cygwin ) and to simplify the code / reduce its madness factor
 - The precondition checks have been reworked to be simpler and more convinient
 - Unox has now been packaged using brew, which makes the installation of unox/unison easier
 - Unox has been upgrading to use watchdog instead of macfsevents, which should improve performance
 - Several installation issues have been fixed
 - Stopping docker-sync now runs synchronously, avoiding accidental race conditions

Thank you a lot for the contributions guys, a lot of team effort in this release!

----

0.2.3
-----
 - Smaller Bugfixes and minor features: https://github.com/EugenMayer/docker-sync/releases/tag/0.2.3

----

0.2.1
-----
 - Smaller bugfixes https://github.com/EugenMayer/docker-sync/milestone/15?closed=1

----

0.2.0
-----
 - You can now start docker-sync in daemon mode ``docker-sync-daemon``. See :ref:`daemon-mode`.
 - The default sync strategy is now unison, no longer rsync. Check :doc:`../getting-started/upgrade`.
 - Unison sync now starts slightly faster
 - New default setting for ``--prefer``: ``--prefer <src> --copyonconflict``. Check :doc:`../getting-started/upgrade`.
 - Detection of macfsevents installation including some edge cases does properly work now `#243`_.
 - You can now run ``docker-sync start --version`` to see your version
 - You can now use spaces in the src/dest path `#211`_.
 - unison:onesideded sync has been entirely removed. Check :doc:`../getting-started/upgrade`.
 - ``sync_user`` option has been removed (use ``sync_userid`` only), since it only spread confusion. Check :doc:`../getting-started/upgrade`.
 - Better way of mounting sync-volumes. Check :doc:`../getting-started/upgrade`.
 - sync_exclude 'type' for unison is now `Name`, not ``Path`` by default. Check :doc:`../getting-started/upgrade`.
 - You can now use environment variables in your docker-sync.yml using ``dotenv``. See :ref:`environment-variables`.
 - unison using ``--testserver`` now to avoid startup issues and also speedup the startup
 - Check for updates only for the actually strategy picked, not all
 - Add support for ``--abort-on-container-exit`` for docker-compose `#163`_.
 - To share more code and features between the rsync / unison images, we aligned those images to share the same codebase, thus they have been renamed. The ENV variables are changed and some things you should not even notice, since it is all handled by docker-sync. Check :doc:`../getting-started/upgrade`.
 - Fix dynamic port detection with unison / make it more robust `#247`_.
 - New and more robust unison/rsync images

.. _#163: https://github.com/EugenMayer/docker-sync/issues/163
.. _#211: https://github.com/EugenMayer/docker-sync/issues/211
.. _#243: https://github.com/EugenMayer/docker-sync/issues/243
.. _#247: https://github.com/EugenMayer/docker-sync/issues/247

----

0.1.2
-----
 - Adjustments and bugfixes
 - Full changelog at: https://github.com/EugenMayer/docker-sync/releases/tag/0.1.2

----

0.1.1
-----
 - Small bugfixes

----

0.1.0
-----
- **Unison-Unox strategy for transparent 2-way sync introduced.**
- Full changelog at: https://github.com/EugenMayer/docker-sync/releases/tag/0.1.0

----

0.0.15
------
- **Notifications, cli mode**
- cli-mode selection https://github.com/EugenMayer/docker-sync/pull/66
- Notifications on sync https://github.com/EugenMayer/docker-sync/pull/63, thank you midN_

.. _midN: https://github.com/midN

----

0.0.14
------
- **Welcome unison-dualside for real 2-way-sync**
- unison-dualside strategy introduced for real 2 way syncing, thank you mickaelperrin_. See :doc:`../advanced/sync-strategies`.
- New `image for rsync`_ based on alpine (10MB), thank you Duske_.
- Optimize fswatch to watch only useful events (better performance), thank you mickaelperrin_
- Different fixes with filepaths, symlinks and some minors
- Detailed list at https://github.com/EugenMayer/docker-sync/milestone/5?closed=1

.. _unison-dualside strategy: https://github.com/EugenMayer/docker-sync/wiki/8.-Strategies
.. _image for rsync: https://github.com/EugenMayer/docker-unison
.. _Duske: https://github.com/Duske

----

0.0.13
------
- **docker-compose-dev.yml make docker-compose.yml portable**
- By moving all changes initially made to your docker-compose.yml into docker-compose-dev.yml, your production docker-compose.yml stays portable `#41`_
- Fixing a bug when docker-sync / docker-sync-stack has been symlinked `#44`_ by mickaelperrin_

.. _#41: https://github.com/EugenMayer/docker-sync/issues/41
.. _#44: https://github.com/EugenMayer/docker-sync/issues/44
.. _mickaelperrin: https://github.com/mickaelperrin

----

0.0.12
-------
- **Unison slim image, docker-compose path and fswatch disabling**
- You can no configure were you docker-compose file is located at. See :doc:`../getting-started/configuration`.
- You can now disable the filewatcher using watch_strategy. See :doc:`../getting-started/configuration`.
- docker-compose gem is now part of the gem
- gem / lib was re-layouted to fit the library usage better
- tons of requires have been fixed for the script usage. See :doc:`../advanced/scripting`.
- A alpine based, slim unison image was created by onnimonni_. Thank you!
- You can now customize which unison/rsync image you want to use (experts only please!)

.. _onnimonni: https://github.com/onnimonni

----

0.0.11
------
- **docker-sync-stack is here**
- **You can now start sync and docker-compose in one go** - See :ref:`sync-stack-commands`.
- rsync image is now checked for update ability to avoid issues with outdated images

----

0.0.10
------

- Yanked, broken release

----

0.0.9
-----
- **Adresses further unison issues, minor features**
- Missing stdout pipe and wrong color, thank you @mickaelperrin
- More verbose outputs on unison runs with verbose,, thank you @mickaelperrin
- Adding update-checker to ensure, that you run the newest docker-sync

----

0.0.8
-----
- **Fix unison startup**
- Fixed issue during unison startup

----

0.0.7
-----
- ** Convenience / Bugfixes**
- **Add the possibility to map user/group on sync**
- Fixed container-re-usage issue
- Add preconditions to properly detect if fswatch, unison, docker, and others are in proper state
- Better log output
- Do no longer enforce verbose flag
- Remove colorize
- Be less verbose in normal mode
- Fixed source code mapping when using test
- Renamed test to example

----

0.0.6
-----
- **Critical issue in sync**
- Fixing critical issue where sync has been called using the old sync:sync syntax - not syncing at all

----

0.0.5
-----
- **Added unison support**
