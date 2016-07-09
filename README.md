## WAT

A huge topic under OSX is, how to mount/share code into docker containers, used for development.
Doing this the classic/native way leads to huge performance issues - that's why docker-sync has been made (next to the [other alternatives](https://github.com/EugenMayer/docker_sync#other-projects-with-similar-purpose-i-know-of))

Docker-sync is:
 - able to run on all of those docker-machines and also on **docker for mac**
 - it uses **rsync or unison** (you can chose) to sync - so the container performance is not influenced at all, see [performance](https://github.com/EugenMayer/docker_sync#performance)
 - an efficient way is used to watch for file changes (fswatch -o) - does not eat up you CPU even for 12k+ files
 - supports either one-way sync ( rsync ) or two way sync ( unison )
 - supports user-remapping on sync to avoid permission problems

So besides performance being the first priority, the second is, not forcing you into using a **specific** docker-toolbox solution.
Use docker-for-mac, dockertoolbox, virtualbox fusion or Paralelles, xhyve or whatever!

## Changelog

**0.0.7** Convinience / Bugfixes
- Fixed container-re-usage issue
- **add the possibility to map user/group on sync**
- Add preconditions to properly detect if fswatch, unison, docker, and others are in proper state
- Better log output
- Do no longer enforce verbose flag
- remove colorize
- be less verbose in normal mode
- Fixed source code mapping when using test
- renamed test to example

See [full changelog](https://github.com/EugenMayer/docker_sync/wiki/Changelog)

## Motivation

I tried a lot of the below named projects, and they did not suite because:
 - they require either a specific docker machine ( forcing vbox e.g. ) or require one at all
 - they use native shares or NFS, which are both way to slow to use them for code-sharing / development

## Installation
See [installation](https://github.com/EugenMayer/docker_sync/wiki/Installation) in the wiki

## Boilerplate / Quickstart

See the boilerplate for a simple, working example : https://github.com/EugenMayer/docker-sync-boilerplate

## Usage

a) Create a docker-sync.yml configuration in your project root, see [configuration](https://github.com/EugenMayer/docker_sync/wiki/Configuration)

b) start the syncronisation with
```
docker-sync start
```
Let docker-sync run in the background

( see ```docker-sync help``` help for more commands )

c) Adjust your docker-compose.yml file [like here](https://github.com/EugenMayer/docker_sync/wiki/Configuration#docker-composeyml)

d) In a new shell run after you started docker-sync
```
docker-compose up
```

**You can now boldly change your code and it will all end up int the app-containers**

e) For cleanup see [leanup](https://github.com/EugenMayer/docker_sync/wiki/docker-sync-commands#clear)

## Tests (sync and performance)
See [tests and sample setup](https://github.com/EugenMayer/docker_sync/wiki/Tests) in the Wiki
or checkout the [docker-sync-boilerplate](https://github.com/EugenMayer/docker-sync-boilerplate)

## Performance
See [performance](https://github.com/EugenMayer/docker_sync/wiki/Performance) in the Wiki

**So the result**: No difference between shared and not shared. That's what we want. And thats faster then anything else.

## TODO
 - Probably use alpine linux for the sync container, to minimize its size
 - Create Wiki pages and slim down the readme - can someone help on this?
 - Do we have windows support? :)
 - I bet you find something! :)

## Other usages with docker_sync

- [as Library](https://github.com/EugenMayer/docker_sync/wiki/Docker-sync-as-library)

## Thanks to
Without the following projects, this project would be empty space and worth nothing. All the credits to them

 - [fswatch](https://emcrisostomo.github.io/fswatch)
 - [rsync](https://de.wikipedia.org/wiki/Rsync)
 - [unison](https://www.cis.upenn.edu/~bcpierce/unison/)
 - [thor](https://github.com/erikhuda/thor)
 - [Homebrew](http://brew.sh/)

## Contributions
**Hell yes**. Pull-requests, Feedback, Bug-Issues are very welcome.

## Alternatives

See [alternatives](https://github.com/EugenMayer/docker_sync/wiki/Alternatives-to-docker-sync)

## License
You can eat, sell or delete this code - just without any warranty of any kind.
Leaving the authors credits would be a friendly way of saying thank you :)
