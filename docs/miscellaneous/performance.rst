Performance
===========

OSX
---

+--------------------------------+-------------------------+-----------------------+
| Setup                          | Native                  | Docker-Sync           |
|                                | (out of the box)        +--------+--------------+
|                                |                         | Unison | :Native_osx  |
+================================+=========================+========+==============+
| Docker Toolbox - VMware Fusion |                  12.31s | 0.24s  | n/a (issue_) |
+--------------------------------+-------------------------+--------+--------------+
| Docker Toolbox - VirtualBox    |                   3.37s | 0.26s  | n/a (issue_) |
+--------------------------------+-------------------------+--------+--------------+
| Docker for Mac                 |                  20.55s | 0.36s  |        0.28s |
+--------------------------------+-------------------------+--------+--------------+
| Docker for Mac Edge            |                  18.12s | 0.27s  |        0.19s |
+--------------------------------+-------------------------+--------+--------------+
| Docker for Mac Edge + AFPS     |                  18.15s | 0.38s  |        0.37s |
+--------------------------------+-------------------------+--------+--------------+
| Docker for Mac Edge :cached_   |                  17.65s | 0.21s  |        0.22s |
+--------------------------------+-------------------------+--------+--------------+

Setup and details at https://github.com/EugenMayer/docker-sync/wiki/Performance-Tests-2017

.. _issue: https://github.com/EugenMayer/docker-sync/issues/346
.. _cached: https://blog.docker.com/2017/05/user-guided-caching-in-docker-for-mac/

Windows
-------

Coming soon.

Linux
-----

Coming soon.
