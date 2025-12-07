#!/bin/bash

URL=$1
FILE=$(basename $URL)

mkdir -p /packages

pushd /packages
if [ ! -f "$FILE" ] ; then
    wget -q $URL
fi
popd

tar  -xaf /packages/$FILE