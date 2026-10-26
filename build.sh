#!/bin/bash
set -e
# The image version is the git tag on the current commit, e.g. v1.15.0
VERSION=$(git describe --tags --exact-match) || { echo "Tag the current commit first (git tag vX.Y.Z)" >&2; exit 1; }
set -x

# Build the build image
docker build -t registry.gitlab.vandertogt.org/tools/docker-build-image:${VERSION} .
docker tag registry.gitlab.vandertogt.org/tools/docker-build-image:${VERSION} registry.gitlab.vandertogt.org/tools/docker-build-image:latest
docker tag registry.gitlab.vandertogt.org/tools/docker-build-image:${VERSION} docker.vandertogt.org/firmware-builder:${VERSION}
#docker image push registry.gitlab.vandertogt.org/tools/docker-build-image:${VERSION}
#docker image push registry.gitlab.vandertogt.org/tools/docker-build-image:latest
docker image push docker.vandertogt.org/firmware-builder:${VERSION}