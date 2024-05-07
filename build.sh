#!/bin/bash
VERSION=v1.6
set -e
set -x

# Build the build image
docker build -t docker.vandertogt.org/firmware-builder:${VERSION} .
docker image push docker.vandertogt.org/firmware-builder:${VERSION}
