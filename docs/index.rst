docker-sync
===========

Run your application at full speed while syncing your code for development, finally empowering you to utilize docker for development under OSX/Windows/Linux*

Introduction
============

Developing with docker_ under OSX/ Windows is a huge pain, since sharing your code into containers will slow down the code-execution about 60 times (depends on the solution). Testing and working with a lot of the alternatives made us pick the best of those for each platform, and combine this in one single tool: ``docker-sync``.

- For OSX, see :ref:`installation-osx`.
- For Windows, see :ref:`installation-windows`.
- For Linux, see :ref:`installation-linux`.
- See the list of alternatives at :doc:`../miscellaneous/alternatives`

.. _docker: https://www.docker.com/

Features
--------

- Support for OSX, Windows, Linux and FreeBSD
- Runs on Docker for Mac, Docker for Windows and Docker Toolbox
- Uses either native_osx, unison or rsync as possible strategies. The container performance is not influenced at all, see :doc:`../miscellaneous/performance`
- Very efficient due to the :ref:`native_osx in depth`
- Without any dependencies on OSX when using (native_osx)
- Backgrounds as a daemon
- Supports multiple sync-end points and multiple projects at the same time
- Supports user-remapping on sync to avoid permission problems on the container
- Can be used with your docker-compose way or the integrated docker-compose way to start the stack and sync at the same time with one command
- Using overlays to keep your production docker-compose.yml untouched and portable. See :ref:`docker-compose-yml`.
- Supports Linux* to use the same toolchain across all platforms, but maps on a native mount in linux (no sync)
- Besides performance being the first priority for docker-sync, the second is, not forcing you into using a specific docker solution. Use docker-for-mac, docker toolbox, VirtualBox, VMware Fusion or Parallels, xhyve or whatever!

.. toctree::
   :hidden:
   :caption: Introduction

   Introduction <self>

.. toctree::
   :hidden:
   :caption: Getting Started
   :maxdepth: 2

   getting-started/installation
   getting-started/configuration
   getting-started/commands
   getting-started/troubleshooting
   getting-started/upgrade

.. toctree::
   :hidden:
   :caption: Advanced
   :maxdepth: 2

   advanced/sync-strategies
   advanced/scripting
   advanced/how-it-works
   advanced/tips-and-tricks

.. toctree::
   :hidden:
   :caption: Miscellaneous
   :maxdepth: 2

   miscellaneous/development-and-testing
   miscellaneous/performance
   miscellaneous/alternatives
   miscellaneous/changelog
