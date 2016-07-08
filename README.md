## WAT

A huge topic under OSX is, how to mount/share code into docker containers, used for development.
Doing this the classic/native way leads to huge performance issues - that's why docker-sync has been made (next to the [other alternatives](https://github.com/EugenMayer/docker_sync#other-projects-with-similar-purpose-i-know-of)

Docker-sync is:
 - able to run on all of those docker-machines and also on **docker for mac**
 - it uses **RSYNC** to sync - so the container performance is not influenced at all, see [performance](https://github.com/EugenMayer/docker_sync#performance)
 - a efficient way is used to watch for file changes (fswatch -o) - does not eat up you CPU even for 12k+ files

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

## Usage
### 1. configuration (once)
Please see [test/docker-sync.yml](https://github.com/EugenMayer/docker_sync/blob/master/test/docker-sync.yml) and check the annotations to understand, how how to configure docker-sync

a) Place your docker-sync.yml in your project root. The configuration will be searched from the point your run docker-sync from, traversing up the path tree

b) You can define as many syncs as you need. Be sure to vary the port, that's basically it

### 2. Start sync/watch process (every time)
```
docker-sync sync:start
```
For further help and commands use

```
docker-sync help
docker-sync help sync
docker-sync help sync:start
docker-sync help sync:sync
docker-sync help sync:clean
```

And so on

### 3. How to mount the synced volumes in my containers? (once)
The sync-name, like fullexample in the example, is the container-name you should mount.
So in you docker-compose.yml you would add

```
version: "2"
services:
  someapp:
    image: alpine
    container_name: 'fullexample_app'
    # that the important thing
    volumes_from:
      - container:fullexample:rw # will be mounted on /var/www
    command: ['watch', '-n1', 'cat /var/www/somefile.txt']
  otherapp:
    image: alpine
    container_name: 'simlpeexample_app'
    command: ['watch', '-n1', 'cat /app/code/somefile.txt']
    # that the important thing
    volumes_from:
      - container:simpleexample:rw # will be mounted on /app/code

# that the important thing
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

**You can no boldly change your code and it will all end up int the containers**

### 5. Cleanup

After you are done and probably either want to free up space or switch to a different project you might want to release the sync containers and volumes by

```
docker-sync sync:clean
```

This will of course not delete anthing on your host source code folders or similar, it just removes the container for rsync and its volumes. It does not touch you application stack

## Behind the scenes
- On the host, a thor based ruby task is started, this starts
  - Every sync will start a own docker-container with a rsync-daemon watching for connections.
  - The data gets pre-synced on sync-start
  - a fswatch cli-task is setup, to run rsync on each file-change in the source-folder you defined

Done. No magic. But its roadrunner fast! And it has no pre-conditions on your actual stack

## Tests (sync and perfomance)
Pull this repo and then
```
cd docker_sync/test
thor sync:start
```
Let this process running

Open a new shell

```
cd docker_sync/test
dc up
```

This starts to containers which cat the file we sync ( data1/somefile.txt and data2/somefile.txt )

Open a third shell and run

```
cd docker_sync/test
echo "NEWVALUE" >> data1/somefile.txt
echo "NOTTHEOTHER" >> data2/somefile.txt
```

Check the docker-compose logs and you see that the files are updated.

Performance

```
docker exec -i -t fullexample_app time dd if=/dev/zero of=/var/www/test.dat bs=1024 count=100000
```

## Performance
Use the test-setup above and try

This writes on a folder which is shares/synced
```
docker exec -i -t fullexample_app time dd if=/dev/zero of=/var/www/test.dat bs=1024 count=100000
100000+0 records in
100000+0 records out
real	0m 0.11s
user	0m 0.00s
sys	0m 0.11s
```

This writes on a folder which is NOT shared
```
docker exec -i -t fullexample_app time dd if=/dev/zero of=/test.dat bs=1024 count=100000      1 ↵
100000+0 records in
100000+0 records out
real	0m 0.15s
user	0m 0.02s
sys	0m 0.13s
```

**So the result**: No difference between shared and not shared. That's what we want. And thats faster then anything else.

## TODO
 - probably use alpine linux for the sync container, to minimize its size
 - Do we have windows support? :)
 - i bet you find something! :)

## Other usages with docker_sync

We use docker-sync as a library in our own docker-stack startup script. It starts the docker-compose stack using
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
Performance: In general, at least 3 times slower the **RSYNC**, ofter even more

 - [Dinghy](https://github.com/codekitchen/dinghy) (docker-machine only)
 - [dlite](https://github.com/nlf/dlite) (docker-machine only)

#### Rsync
Performance: Exactly the performance you would have without shares. Perfect!
 - [docker-dev-osx](https://github.com/brikis98/docker-osx-dev) (rsync, vbox only)

Hint: If you are happy with docker-machine and virtual box, this is a pretty solid alternative. It has been there for ages and is most probably pretty advanced. For me, it was no choice, since neither i want to stick to VBox nor it has support for docker-for-mac
#### Unison
Performance: Not sure, i suggest similar to RSYNC. You have to implement watch-ing yourself though
 - [Hodor](https://github.com/gansbrest/hodor) (should be as fast as rsync?)

Hint: Tried unison, but i do not like the idea behind 2-way sync for development. If you need this, it should be a conceptual issue with your docker image architecture.
Beside that, it does not support docker for mac
####Native

Performance: Well, i had everything, from 2-100 times slower to NFS and even more to rsync. **Useless**
 - dockertoolbox: virtualBox / fusion (native, horribly slow)
 - docker for mac (osxfs, 2/3 slower then NFS)

## License
You can eat, sell or delete this code - just without any warranty of any kind.
Leaving the authors credits would be a friendly way of saying thank you :)
