#!/bin/bash

BASE_DIR="`dirname \"$0\"`"
BASE_DIR="`( cd \"$BASE_DIR\" && pwd )`"
TOP_DIR="$BASE_DIR/.."

. $TOP_DIR/lib/general
. $TOP_DIR/lib/yaml
. $TOP_DIR/lib/settings

if [ -n "$1" ]; then
 environments="$1"
fi

echo Cleaning up environments under $environments
find $environments -type f -name effective.keys | xargs rm -f
find $environments -type f -name environment | xargs rm -f
find $environments -type f -regex '.*\.qcow2' | xargs rm -f

