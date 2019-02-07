***********
Performance
***********

Performance
===========

OSX
---

+--------------------------------+-------------------------+-----------------------+
| Setup                          | Native                  | Docker-Sync           |
|                                | (out of the box)        +--------+--------------+
|                                |                         | Unison |  native_osx  |
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

Setup and details below at :ref:`performance-tests-2017`.

.. _issue: https://github.com/EugenMayer/docker-sync/issues/346
.. _cached: https://blog.docker.com/2017/05/user-guided-caching-in-docker-for-mac/

Windows
-------

Coming soon.

Linux
-----

Coming soon.

----

.. _performance-tests-2017:

Performance Tests 2017
======================

Results
-------

Test: writing 100MB


+--------------------------------+-------------------------+-----------------------+
| Setup                          | Native                  | Docker-Sync           |
|                                | (out of the box)        +--------+--------------+
|                                |                         | Unison |  native_osx  |
+================================+=========================+========+==============+
| Docker Toolbox - VMware Fusion |                   8.70s | 0.22s  | n/a (issue_) |
+--------------------------------+-------------------------+--------+--------------+
| Docker Toolbox - VirtualBox    |                   3.37s | 0.26s  | n/a (issue_) |
+--------------------------------+-------------------------+--------+--------------+
| Docker for Mac                 |                  18.85s | 0.24s  |        0.28s |
+--------------------------------+-------------------------+--------+--------------+
| Docker for Mac Edge            |                  18.12s | 0.27s  |        0.19s |
+--------------------------------+-------------------------+--------+--------------+
| Docker for Mac Edge :cached_   |                  17.65s | 0.21s  |        0.22s |
+--------------------------------+-------------------------+--------+--------------+

.. _issue: https://github.com/EugenMayer/docker-sync/issues/346
.. _cached: https://blog.docker.com/2017/05/user-guided-caching-in-docker-for-mac/

Those below is how the tests were made and how to reproduce them:

Setup
-----

Test-hardware
^^^^^^^^^^^^^

 - i76600u
 - 16GB
 - SSD
 - Sierra

Docker Toolbox VMware Fusion machine:
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: shell

  docker-machine create --driver vmwarefusion --vmwarefusion-cpu-count 2 --vmwarefusion-disk-size 50000 --vmwarefusion-memory-size 8000 default

Docker for Mac
^^^^^^^^^^^^^^

- 8GB
- CPUs

Native implementations
----------------------

Those tests run without docker-sync or anything, just plain what you get out of the box.

VirtualBox - Native
^^^^^^^^^^^^^^^^^^^

.. code-block:: shell

    docker-machine create --driver virtualbox --virtualbox-cpu-count 2 --virtualbox-disk-size 20000 --virtualbox-memory "8000" vbox

.. code-block:: shell

    docker run -it -v /Users/em/test:/var/www alpine time dd if=/dev/zero of=/var/www/test.dat bs=1024 count=100000
    100000+0 records in
    100000+0 records out
    real  0m 3.37s
    user  0m 0.00s
    sys 0m 2.09s

**3.37s**

VMware Fusion - Native
^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: shell

    docker run -it -v /Users/em/test:/var/www alpine time dd if=/dev/zero of=/var/www/test.dat bs=1024 count=100000
    100000+0 records in
    100000+0 records out
    real  0m 12.32s
    user  0m 0.14s
    sys 0m 2.22s

**12.31s**

Docker for Mac - Native
^^^^^^^^^^^^^^^^^^^^^^^^

- 8GB Ram
- 2 CPUs

.. code-block:: shell

    docker run -it -v /Users/em/test:/var/www alpine time dd if=/dev/zero of=/var/www/test.dat bs=1024 count=100000
    100000+0 records in
    100000+0 records out
    real  0m 18.85s
    user  0m 0.11s
    sys 0m 1.06s

**20.55s**

Docker-sync - Strategy: Native_osx
----------------------------------

Get this repo and this boilerplate project

.. code-block:: shell

    git clone https://github.com/EugenMayer/docker-sync-boilerplate
    cd docker-sync-boilerplate/default
    docker-sync-stack start

Vmware Fusion
-------------

.. code-block:: shell

    docker exec -it nativeosx_app-unison_1 time dd if=/dev/zero of=/var/www/test.dat bs=1024 count=100000
    100000+0 records in
    100000+0 records out
    real  0m 0.32s
    user  0m 0.02s
    sys 0m 0.24s

**0.32s**

Docker for Mac
--------------

.. code-block:: shell

    docker exec -it nativeosx_app-unison_1 time dd if=/dev/zero of=/var/www/test.dat bs=1024 count=100000
    100000+0 records in
    100000+0 records out
    real  0m 0.28s
    user  0m 0.02s
    sys 0m 0.25s

**0.26s**

Docker-Sync - Strategy: Unison
------------------------------

Get this repo and this boilerplate project

.. code-block:: shell

    git clone https://github.com/EugenMayer/docker-sync-boilerplate
    cd docker-sync-boilerplate/unison
    docker-sync-stack start

VirtualBox
----------

.. code-block:: shell

    docker exec -it unison_app-unison_1 time dd if=/dev/zero of=/var/www/test.dat bs=1024 count=100000
    100000+0 records in
    100000+0 records out
    real  0m 0.26s
    user  0m 0.00s
    sys 0m 0.23s


VMware Fusion
-------------

.. code-block:: shell

    docker exec -it unison_app-unison_1 time dd if=/dev/zero of=/var/www/test.dat bs=1024 count=100000
    100000+0 records in
    100000+0 records out
    real  0m 0.24s
    user  0m 0.01s
    sys 0m 0.23s

Docker for Mac
--------------

.. code-block:: shell

    docker exec -it unison_app-unison_1 time dd if=/dev/zero of=/var/www/test.dat bs=1024 count=100000
    100000+0 records in
    100000+0 records out
    real  0m 0.24s
    user  0m 0.04s
    sys 0m 0.16s

**0.36s**
