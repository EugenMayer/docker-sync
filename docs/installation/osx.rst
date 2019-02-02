Docker-sync on OSX
==================

Dependencies
------------
With native_osx we no longer have any host dependencies.

Advanced / optional
-------------------
Optionally, if you do not want to use unison or want a better rsync or use unison (than the built-in OS X one)

**if you use unison**

.. code-block:: shell

    brew install unison
    brew install eugenmayer/dockersync/unox

**if you use rsync**

.. code-block:: shell

    brew install rsync

Homebrew aka brew is a tool you need under OSX to install / easy compile other tools. You can use other tools/ways to install or compile fswatch, but those are out of scope for this docs. All we need is the binary in PATH.
