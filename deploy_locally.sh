#!/bin/bash
rm -f docker-sync-*.gem
gem build docker-sync.gemspec
version=`cat VERSION`
echo| gem uninstall -a --force -q docker-sync
gem install docker-sync-*.gem
rm -f docker-sync-*.gem

