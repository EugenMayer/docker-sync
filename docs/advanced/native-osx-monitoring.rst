native_osx Advanced Monitoring
==============================

Background
----------

Monit_ is a utility which can be used to monitor the health of the ``unison`` process which runs in the container for the ``native_osx`` strategy. If it detects that ``unison`` is unhealthy, Monit automatically restarts ``unison``. This improves the stability of the ``native_osx`` container in cases where the ``unison`` process is misbehaving but does not necessarily crash. Currently, there is only one check for CPU usage implemented, but in the future more checks may be added, such as memory usage. It is currently turned off by default and can be turned on in the configuration:

https://github.com/EugenMayer/docker-sync/blob/master/example/docker-sync.yml#L120-L126

.. _Monit: https://mmonit.com/monit/

Monitoring of the CPU usage
---------------------------

One instance which ``unison`` has been seen to misbehave is when quickly creating and deleting a file while it is processing it. ``unison`` may hang, using a high amount of cpu time: https://github.com/EugenMayer/docker-sync/issues/497. ``monit`` detects this high cpu usage (>50%) and automatically restarts ``unison`` to recover it. By default this happens within 10 seconds, but the tolerance can be configured in case there are normal spikes in cpu usage during successful syncs.
