Windows Home
============

Benefits of Docker-sync on Windows
----------------------------------

- Inotify works on containers that support it. No more polling!
- Performance might be a bit better or right on par with native Windows volumes. This needs more testing.

Current Documented/Working Environments for Windows
---------------------------------------------------

- `Ubuntu Bash on Windows`_ (WSL)

.. _Ubuntu Bash on Windows: https://github.com/EugenMayer/docker-sync/wiki/docker-sync-on-Windows

Possible Future Supported Environments
--------------------------------------

- Cygwin
- Native Windows (no posix)
