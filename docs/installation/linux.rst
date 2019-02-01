Docker-sync on Linux
====================
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
