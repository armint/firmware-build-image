#!/bin/bash

set -e
set -x

# Build the build image
docker build -t docker.vandertogt.org/firmware-builder:v1.3 .
docker image push docker.vandertogt.org/firmware-builder:v1.3
