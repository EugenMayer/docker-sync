docker-sync
=======================================

Run your application at full speed while syncing your code for development, finally empowering you to utilize docker for development under OSX/Windows/Linux*

Introduction
============

Developing with docker_ under OSX_/ Windows_ is a huge pain, since sharing your code into containers will slow down the code-execution about 60 times (depends on the solution). Testing and working with a lot of the alternatives_ made us pick the best of those for each platform, and combine this in one single tool: docker-sync

Features
---------------------

- Support for OSX, Windows, Linux and FreeBSD
- Runs on Docker for Mac, Docker for Windows and Docker Toolbox
- Uses either native_osx_, unison or rsync as possible strategies_. The container performance is not influenced at all, see performance_
- Very efficient due to the `native_osx concept`_
- Without any dependencies on OSX when using (native_osx)
- Backgrounds as a daemon
- Supports multiple sync-end points and multiple projects at the same time
- Supports user-remapping on sync to avoid permission problems on the container
- Can be used with your docker-compose way or the integrated docker-compose way to start the stack and sync at the same time with one command
- Using overlays_ to keep your production docker-compose.yml untouched an portable
- Supports `Linux*`_ to use the same toolchain across all platforms, but maps on a native mount in linux (no sync)
- Besides performance being the first priority for docker-sync, the second is, not forcing you into using a specific docker solution. Use docker-for-mac, docker toolbox, VirtualBox, VMware Fusion or Parallels, xhyve or whatever!



.. _docker: https://www.docker.com/
.. _OSX: https://github.com/EugenMayer/docker-sync/wiki/docker-sync-on-OSX
.. _Windows: https://github.com/EugenMayer/docker-sync/wiki/docker-sync-on-Windows
.. _alternatives: https://github.com/EugenMayer/docker_sync/wiki/Alternatives-to-docker-sync
.. _native_osx: https://github.com/EugenMayer/docker-sync/wiki/How-does-native_osx-work-with-OSXFS-and-is-still-native-speed-fast%3F
.. _strategies: https://github.com/EugenMayer/docker-sync/wiki/8.-Strategies
.. _performance: https://github.com/EugenMayer/docker_sync/wiki/4.-Performance
.. _native_osx concept: https://github.com/EugenMayer/docker-sync/wiki/How-does-native_osx-work-with-OSXFS-and-is-still-native-speed-fast%3F
.. _overlays: https://github.com/EugenMayer/docker-sync/wiki/2.-Configuration#docker-composeyml--docker-compose-devyml
.. _Linux*: https://github.com/EugenMayer/docker-sync/wiki/docker-sync-on-Linux

.. toctree::
   :hidden:
   :maxdepth: 2

   Introduction <self>

.. toctree::
   :hidden:
   :caption: Installation
   :maxdepth: 3

   installation/installation
   installation/osx
   installation/linux
   installation/windows
