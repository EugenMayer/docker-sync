#!/bin/bash
gem build docker-sync.gemspec
version=`cat VERSION`
gem uninstall docker-sync
gem install docker-sync-$version.gem
