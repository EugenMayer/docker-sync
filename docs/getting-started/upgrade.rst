Upgrade
=======

0.4.2-0.4.5
-----------

Nothing special, just be sure to pull the newest docker-images for your strategy and do not leave any older version behind

----

0.4.1
-----
- ``:nocopy`` needs to be added to all named-volume mounts, see :ref:`why-nocopy-important`

- if you want to use native_osx with docker-machine ( toolbox ) + virtualbox, it will not work https://github.com/EugenMayer/docker-sync/issues/346

The ``:nocopy`` issue has been there for a while, but nobody really recognized it.

----

0.4.0
-----

.. attention::

    Ensure you run docker-sync clean after the upgrade. Do not reuse the old containers!

**The default strategy is now native_osx**

Read more at :ref:`strategies-native-osx`.

**Background by default**

``docker-sync start`` does now background by default, use ``--foreground`` to run in foreground.

**sync_user now removed**

Being deprecated in 0.2, it's now throwing an error if still present

**docker-sync-daemon is now deprecated**

It's deprecated and will be removed in 0.5

----

0.3.0
-----

**Reinstallation of unox**

Due to a lot of issues and inconvenience with the installation of unox and the lack of versioning of unox, i took the step to create a homebrew formula myself, while working with the unox author hand in hand. This way we can ease up the installation and also be able to avoid issues as https://github.com/EugenMayer/docker-sync/issues/296 The installer will take care of everything for you in this regard

**Scaffolding usages needs to be migrated**

If you scaffolded / scripted with docker-sync using it as a ruby lib, you will now need to change your implementation due to the changes to preconditions and config. Important new/replacing calls are. Please see the updated example at :doc:`../advanced/scripting` for how to load the project config, how to get its path and how to call the preconditions

**Dest has been removed**

After making dest deprecated in the 0.2 release, since we introduce named volume mounts, it is now removed. Just remove it, the destination is set in the docker-compose-dev.yml file like this

.. code-block:: shell

    version: "2"
    services:
      someapp:
       volumes:
         - fullexample-sync:/var/www:rw # will be mounted on /var/www

So here, the destination will be ``/var/www``

----

0.2.0+
------

**Versioning of docker-sync.yml**

From 0.2.0 you need to add a new setting to your docker-sync.yml ``version: "2"`` - this describes the project version you are using. This is needed so later we can easily detect old/incompatible configuration files and warn you to migrate those. This is now mandatory. See this change_ on the boilerplates / examples, which may explain it even better.

**Unison exclude syntax is Name by default now - migrate your entries**

Prior to 0.2.0 the exclude default syntax of the unison strategy was "Path" - since we decided that this is counter-intuitive in most cases, we have changed the default to ``Name`` - please see the `unison documentation for more`_ - mostly you would have expected the ``Name`` behavior anyway, so you might want to stick with it. TLTR: ``Path`` math matches the exact path ( not sub-directories ) while name just matches string on the path - no matter which "nesting level". You could go back to ``Path`` by setting sync_exclude_type_ to 'Path'.

See this issue: `Make Name the default exclude_type in 0.2.0`_.

**rsync trailing slash changes**

Prior to 0.2.0 the trailing slash was automatically added - but now you have to do this explicitly If you define an rsync sync, you most probably want to sync the inner folder into you destination, without creating the parent folder / syncing it. This trailing slash ``./your-code/`` ensures exactly that, so ``your-code`` will not be created on your destination, but anything inside it will be synced.

**Default sync is now unison (from rsync to unison)**

If you did not provide the sync_strategy setting prior 0.2.0 - rsync was used. Starting with 0.2.0 unison(dual sided) is the new default, so a 2 way sync. Beside its just being better, faster after the initial sync and also offers 2-way sync, it has a new Exclude-syntax. With 0.2.0 the ``Name`` exclude syntax is used, ensure you adjust your rsync ones to fit those.

See this issue: `Migration Guide from rsync to unison as default`_.

**volumes_from: container: syntax is no longer used**

The ``volumes_from: container:app-sync:rw`` syntax is no longer used as a volume mount for the sync container, but rather ``volumes: app-sync:/var/www:rw``

See this issue: `Rework the way we mount the volume`_.

**--prefer is now built in - remove it from sync_args**

If you have used sync_args for unison and defined ``--prefer``, please consider removing it. Without doing anything, docker-sync will now use ``--prefer <srcpath> --copyonconflict`` and also help you keep the src dynamic (depending on the developer).

**The option sync_user no longer exists**

``sync_user`` has been removed, since it does not add any useful stuff, but spreads a lot of confusion. Please use ``sync_userid`` solely to define the user-mapping, no need to manually set the ``sync_user`` anymore.

**Remove the old unison:unox image**

Since the name was misleading anyway, please remove the old unison image: ``docker image rm eugenmayer/unison:unox``.

**The rsync / unison images have been remade and aligned**

To share more code and features between the rsync / unison images, we aligned those images to share the same codebase, thus they have been renamed. The ENV variables have changed and some things you should not even notice, since it is all handled by ``docker-sync`` - all you need to know is, you need to pull the new versions if you have disabled the auto-pull (which you should not).

.. _change: https://github.com/EugenMayer/docker-sync-boilerplate/commit/9d2cd625282f968161e3ecf4ed85b5b52dbd8cbd
.. _unison documentation for more: http://www.cis.upenn.edu/~bcpierce/unison/download/releases/stable/unison-manual.html#ignore
.. _sync_exclude_type: https://github.com/EugenMayer/docker-sync/blob/master/example/docker-sync.yml#L56
.. _Make Name the default exclude_type in 0.2.0: https://github.com/EugenMayer/docker-sync/issues/133
.. _Rework the way we mount the volume: https://github.com/EugenMayer/docker-sync/issues/116
.. _Migration Guide from rsync to unison as default: https://github.com/EugenMayer/docker-sync/issues/115
