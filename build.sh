#!/bin/bash
VERSION=v1.9
set -e
set -x

# Build the build image
docker build -t registry.gitlab.vandertogt.org/tools/docker-build-image:${VERSION} .
docker tag registry.gitlab.vandertogt.org/tools/docker-build-image:${VERSION} registry.gitlab.vandertogt.org/tools/docker-build-image:latest
docker image push registry.gitlab.vandertogt.org/tools/docker-build-image:${VERSION}
docker image push registry.gitlab.vandertogt.org/tools/docker-build-image:latest
