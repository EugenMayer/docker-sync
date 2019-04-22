************
Installation
************

No matter if its OSX/Linux/Windows

.. code-block:: shell

    gem install docker-sync

Depending on the OS, you might need more steps to setup. Continue reading below.

----

.. _installation-osx:

OSX
===

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

----

.. _installation-linux:

Linux
=====

.. caution::

    Linux support is still to be considered BETA - do not get too crazy if we have bugs!

Dependencies
------------
Default sync strategy for linux (native) do not need any host dependencies.

Advanced / optional
-------------------
Optionally, if you want to use unison, then you would need to install some more stuff.

The following instructions are written for Ubuntu; if you're using another linux flavor, you might need to adjust some stuff like using a different package manager.

**Using Unison Strategy**

The Ubuntu package for unison doesn't come with unison-fsmonitor, as such, we would need to build from source.

.. code-block:: shell

    sudo apt-get install build-essential ocaml
    wget https://github.com/bcpierce00/unison/archive/v2.51.2.tar.gz
    tar xvf v2.51.2.tar.gz
    cd unison-2.51.2
    make UISTYLE=text
    sudo cp src/unison /usr/local/bin/unison
    sudo cp src/unison-fsmonitor /usr/local/bin/unison-fsmonitor

and that should be enough to get you up and running using unison.

**Using rsync strategy**

rsync strategy is not currently supported under linux, but it can be done. If you need this, please see #386, and send us some help.

----

.. _installation-windows:

Windows
=======

.. caution::

    Windows support is still to be considered BETA, - do not get too crazy if there are some bugs!

This guide provides detailed instructions on getting docker-sync running on Windows Subsystem for Linux.

As the time goes by these instructions may not be updated, so please also check out the repo's issues if you have any 'unknown' problem that is not treated in this guide.

Still the procedure is pretty straightforward and should help set you up and running without too much hassle.

Benefits of Docker-sync on Windows
----------------------------------

- Inotify works on containers that support it. No more polling!
- Performance might be a bit better or right on par with native Windows volumes. This needs more testing.

Possible Future Supported Environments
--------------------------------------

- Cygwin
- Native Windows (no posix)


My Setup (for reference)
------------------------

Windows 10 Pro 1709

Pro version required for using Docker for Windows (Hyper-V), also update your system to the latest available version from MS

Docker for Windows CE 18.03.0-ce-rc3-win56 (16433) edge

(stable version should also work fine)

Let's go!
---------

1. Enable WSL
Open the Windows Control Panel, Programs and Features, click on the left on Turn Windows features on or off and check Windows Subsystem for Linux near the bottom.

2. Install a distro
Open the Microsoft Store and search for 'linux'.

You will be then able to choose and install Debian, SUSE, openSUSE, Ubuntu, etc..

In this guide I am using Debian GNU/Linux. Direct link for Debian GNU/Linux

3. Launch and update
The distro you choose is now an 'app' on your system.

Open the start menu and launch it, then follow the on screen instructions in order to complete the installation.

When you have a fully working shell, update the system.

.. code-block:: shell

    sudo apt update

    sudo apt upgrade

4. Install Docker
Follow the official documentation for installing Docker on Linux: (the following is for Debian)

https://docs.docker.com/install/linux/docker-ce/debian/#install-docker-ce

Note that the Docker Server doesn't work on the subsystem - we will then expose Docker for Windows to WSL later

with Windows 10 >= 1803 you can place a symlink to the Windows binary

.. code-block:: shell

    sudo ln -s "/mnt/c/Program Files/Docker/Docker/resources/bin/docker.exe" /usr/local/bin/docker

5. Install Docker Compose

.. code-block:: shell

    sudo apt install docker-compose

Or if that does not work, follow the official documentation: https://docs.docker.com/compose/install/

with Windows 10 >= 1803 you can place a symlink to the Windows binary

.. code-block:: shell

    sudo ln -s "/mnt/c/Program Files/Docker/Docker/resources/bin/docker-compose.exe" /usr/local/bin/docker-compose

6. Install Ruby and Ruby-dev

.. code-block:: shell

    sudo apt-get install ruby ruby-dev

7. Install docker-sync

Install the gem

.. code-block:: shell

    sudo gem install docker-sync

8. Set your Docker for Windows host as an ENV variable

Open the Docker for Windows settings and check Expose daemon on tcp://localhost:2375 without TLS

Then type the following command in your WSL shell.

.. code-block:: shell

    echo "export DOCKER_HOST=tcp://127.0.0.1:2375" >> ~/.bashrc

9. Compile and install OCaml

Before doing this please check out first the OCaml release changelog and ensure that the OCaml version that you are going to install is compatible. (https://github.com/ocaml/ocaml/releases)

Install build script

.. code-block:: shell

    sudo apt-get install build-essential

As for now the procedure is as follows:

.. code-block:: shell

    sudo apt-get install make
    wget http://caml.inria.fr/pub/distrib/ocaml-4.06/ocaml-4.06.0.tar.gz
    tar xvf ocaml-4.06.0.tar.gz
    cd ocaml-4.06.0
    ./configure
    make world
    make opt
    umask 022
    sudo make install
    sudo make clean

10. Compile and install Unison

Look up the latest Unison release (https://github.com/bcpierce00/unison/releases), download the source code, compile and install.

As for now the procedure is as follows:

.. code-block:: shell

    wget https://github.com/bcpierce00/unison/archive/v2.51.2.tar.gz
    tar xvf v2.51.2.tar.gz
    cd unison-2.51.2
    make UISTYLE=text
    sudo cp src/unison /usr/local/bin/unison
    sudo cp src/unison-fsmonitor /usr/local/bin/unison-fsmonitor

11. Set Timezone if not done already

Check if /etc/localtime is a symlink. If not run dpkg-reconfigure tzdata and set your correct timezone.

12. (bonus!) Bind custom mount points to fix Docker for Windows and WSL differences (thanks to @nickjanetakis)

You might encounter various strange problems with volumes while starting up Docker containers from WSL.

If so, as a workaround you have to set up a special mountpoint inside /etc/fstab and start your container from there.

.. code-block:: shell

    sudo mkdir /c
    sudo mount --bind /mnt/c /c
    echo "sudo mount --bind /mnt/c /c" >> ~/.bashrc && source ~/.bashrc

In order to automatically mount the volume without asking any password you can add a rule into your sudoers file.

.. code-block:: shell

    sudo visudo

Add the following at the bottom of the file, replacing "username" with your WSL username.

.. code-block:: shell

    username ALL=(root) NOPASSWD: /bin/mount

with Windows 10 >= 1803 you can place a new file to /etc/wsl.conf instead

.. code-block:: shell

    [automount]
    root = /
    options = "metadata"

12. Laradock? No problem!

If, as an example, you are using Laradock, you just need to follow the official documentation changing the sync strategy to 'unison' and adding the docker-compose.sync.yml in your .env file.

.. code-block:: shell

    ...
    COMPOSE_PATH_SEPARATOR=;
    COMPOSE_FILE=docker-compose.yml:docker-compose.dev.yml:docker-compose.sync.yml
    ...
    DOCKER_SYNC_STRATEGY=unison

Then you need to add the following 'sync_args' line in the laradock/docker-sync.yml file, as follows:

.. code-block:: shell

    ...
    sync_strategy: '${DOCKER_SYNC_STRATEGY}' # for osx use 'native_osx', for windows use 'unison'

    sync_args: ['-perms=0'] #required for two way sync ie generators, etc
    ...

This will allow proper synchronization between the Linux containers and your Windows host that manages permissions in a different way.

Now you can start syncing using sync.sh provided with Laradock.

.. code-block:: shell

    ./sync.sh up nginx mysql phpmyadmin

Done!

You should now have a working version of docker-sync via the Unison strategy.

In your home directory in WSL you can link your projects from Windows and run docker-sync or docker-sync-stack.

The rest of your workflow should be the same as before in either Command Prompt, PowerShell, or some other Windows terminal.

FYI - An example of a docker-sync.yml file

.. code-block:: yaml

    version: "2"
    options:
        verbose: true
    syncs:
        app-unison-sync: # tip: add -sync and you keep consistent names als a convention
            sync_args: ['-perms=0'] #required for two way sync ie generators, etc
            sync_strategy: 'unison'
            sync_host_ip: '127.0.0.1' #host ip isn't properly inferred
            sync_excludes: ['.gitignore', '.idea/*','.git/*', '*.coffee', '*.scss', '*.sass','*.log']
            src: './'

----

.. _installation-freebsd:

FreeBSD
=======

.. caution:

    FreeBSD support should be considered BETA.

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
