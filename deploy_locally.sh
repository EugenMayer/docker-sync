#!/bin/bash
gem build docker-sync.gemspec
version=`cat VERSION`
echo| gem uninstall -a --force -q docker-sync
gem install docker-sync-$version.gem
rm docker-sync-$version.gem
