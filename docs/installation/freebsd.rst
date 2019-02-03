Docker-sync on FreeBSD
======================

.. caution:

    FreeBSD support should be considered BETA

Dependencies
------------

Default sync strategy for FreeBSD is ``rsync``, you need to install it first:

.. code-block:: shell

    # pkg install rsync

Using ``rsync``
---------------

To setup an rsync resource you need a ``docker-sync.yml`` similar to:

.. code-block:: yaml

    version: "2"

    syncs:
      code-sync:
        sync_strategy: "rsync"
        src: "path/to/src"
        sync_host_port: 10871
        # sync_host_allow: "..."

``sync_host_port`` is mandatory and it must be unique for this shared resource.

You might need to specify ``sync_host_allow``, this will let the rsync daemon know from which IP to expect connections from, network format (``10.0.0.0/8``) or an specific IP (``10.2.2.2``) is supported. The value depends on your virtualization solution and network stack defined (``NAT`` vs ``host-only``). A quick way to determine the value is to run ``docker-sync start`` and let it fail, the error will show you the needed IP value.

Using ``unison``
----------------

``unison`` could be supported on FreeBSD, but it wasn't tested yet.

Using ``native_osx``
--------------------

This strategy is not supported, its OSX only.
