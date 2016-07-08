## WAT

A huge topic under OSX is, how to mount/share code into docker containers, used for development.
Doing this the classic/native way, leads to huge performance issues - that's why docker-sync has been made

Docker-sync is:
 - able to run on all of those docker-machines and also on **docker for mac**
 - it uses **RSYNC** to sync - so the container performance the same as non shares
 - a efficient way is used to watch for file changes (fswatch -o)

So beside performance being the first priority, the second is, not forcing you into using a **specific** docker-toolbox solution.
Use docker-for-mac, dockertoolbox, virtualbox fusion or Paralelles, xhyve or whatever!

## Motivation

I tried a lot of the below named projects, and they did not suite out of this reasons:
 - they require either a specific docker machine ( forcing vbox e.g. ) or require one at all
 - they use native shares or NFS, which are both way to slow to use them for code-sharing / development

## Installation

```
gem install docker-sync
```

## usage
### 1. configuration (once)
Please see test/config.yml and look for the annotations of the configuration values
 - You can define as many syncs as you need. Be sure to vary the port, that's basically it

### 2. Start sync/watch process (every time)
```
docker-sync sync:start
```

### How to mount the synced volumes in my containers? (once)
The sync-name, like fullexample in the example, is the container-name you should mount.
So in you docker-compose.yml you would add

```
version:2
services:
  someapp:
    image: alpine
    volumes_from:
      - container:fullexample:rw # will be mounted on /var/www
  otherapp:
    image: alpine
    volumes_from:
      - container:simpleexample:rw # will be mounted on /app/code

volumes:
  fullexample:
    external: true
  simpleexample:
    external: true
```

That's it, so just define that the volumes are created externally and then reference the volumes in your containers. Done.

### 4. Start your stack

run after you started your sync
```
docker-compose up
```
## Behind the scenes
- On the host, a thor based ruby task is started, this starts
  - Every sync will start a own docker-container with a rsync-daemon watching for connections.
  - The data gets pre-synced on sync-start
  - a fswatch cli-task is setup, to run rsync on each file-change in the source-folder you defined

Done. No magic. But its roadrunner fast! And it has no pre-conditions on your actual stack

## Other usages with docker_sync

We use docker-sync as a library in our own docker-stack startup scrip. It starts the docker-compose stack using
a ruby gem [docker-compose](https://github.com/EugenMayer/docker-compose) all this wrapped into a thor task. So
 - start docker-rsync
 - start a docker-compose stack based on some arguments like --dev and load the specific docker-compose files for that using [docker-compose](https://github.com/xeger/docker-compose)

## Thanks to
Without those to project, this project would be empty space and worth nothing. All the credits to them

 - [fswatch](https://emcrisostomo.github.io/fswatch)
 - [rsync](https://de.wikipedia.org/wiki/Rsync)
 - [thor](https://github.com/erikhuda/thor)

## Contributions
**Hell yes**. Pull-requests, Feedback, Bug-Issues are very welcome.

## Other projects with similar purpose (i know of)
#### NFS
Performance: In general, at least 3 times slower the **RSYNC**, mostly eene more

 - Dinghy (docker-machine only)
 - dlite (docker-machine only)

#### Rsync
Performance: Exactly the performance you would have without shares. Perfect!
 - docker-dev-osx (rsync, vbox only)

#### Unison
Performance: Not sure, i suggest similar to RSYNC. You have to implement watch-ing yourself though
 - only custom made?

Hint: Tried unison, but i do not like the idea behind 2-way sync for development. If you need this, it should be a conceptual issue with your docker image architecture
####Native

Performance: Well, i had everything, from 2-100 times slower to NFS and even more to rsync. **Useless**
 - dockertoolbox: virtualBox / fusion (native, horribly slow)
 - docker for mac (osxfs, 2/3 slower then NFS)

## License
You can eat, sell or delete this code - just without any warranty of any kind.
Leaving the authors credits would be a friendly way of saying thank you :)
