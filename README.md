## WAT

A huge topic under OSX is, how to mount/share code into docker containers, used for development.
Doing this the classic/native way leads to huge performance issues - that's why docker-sync has been made (next to the [alternatives](https://github.com/EugenMayer/docker_sync/wiki/Alternatives-to-docker-sync))

Docker-sync is:
 - able to run on all of those docker-machines and also on **docker for mac**
 - it uses **rsync or unison** (you can chose) to sync - so the container performance is not influenced at all, see [performance](https://github.com/EugenMayer/docker_sync/wiki/4.-Performance)
 - an efficient way is used to watch for file changes (fswatch -o) - does not eat up you CPU even for 12k+ files
 - supports either one-way sync ( rsync ) or two way sync ( unison )
 - **supports user-remapping on sync to avoid permission problems**

Besides performance being the first priority for docker-sync, the second is, not forcing you into using a **specific** docker-toolbox solution.
Use docker-for-mac, docker toolbox, VirtualBox, VMware Fusion or Paralells, xhyve or whatever!

## Anything else

[Documenation and antyhing else can be found in the wiki on gitub](https://github.com/EugenMayer/docker_sync/wiki)