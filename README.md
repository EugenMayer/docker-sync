## WAT
Developing with docker under OSX is a huge pain, since sharing code into docker containers make the code-execution about 50 times slower (depends on the solution). Testing and working with a lot of the [alternatives](https://github.com/EugenMayer/docker_sync/wiki/Alternatives-to-docker-sync) made me pick the best of those, and combine this in one single tool: docker-sync

```
gem install docker-sync
```

Docker-sync is:
 - able to run on all of those docker-machines and also on **docker for mac**
 - it uses either **rsync** or **unison** to sync. The container performance is not influenced at all, see [performance](https://github.com/EugenMayer/docker_sync/wiki/4.-Performance)
 - efficient in its way to watch for file changes - even for 12k+ files it will not eat up you CPU
 - supports either one-way sync ( rsync ) or two way sync ( unison )
 - **supports user-remapping on sync to avoid permission problems on the container**

Besides performance being the first priority for docker-sync, the second is, not forcing you into using a **specific** docker solution. Use docker-for-mac, docker toolbox, VirtualBox, VMware Fusion or Parallels, xhyve or whatever!

## Documentation, Installation, Configuration

All the information is provided [in the Wiki](https://github.com/EugenMayer/docker_sync/wiki)