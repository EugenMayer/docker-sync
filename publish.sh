#!/bin/bash
gem build docker-sync.gemspec
version=`cat VERSION`
gem push docker-sync-$version.gem
rm docker-sync-$version.gem
