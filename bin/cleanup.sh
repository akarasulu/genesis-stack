#!/bin/bash

BASE_DIR="`dirname \"$0\"`"
BASE_DIR="`( cd \"$BASE_DIR\" && pwd )`"
TOP_DIR="$BASE_DIR/.."

. $TOP_DIR/lib/general
. $TOP_DIR/lib/yaml
. $TOP_DIR/lib/settings

if [ -n "$1" -a "$1" != "vm" ]; then
 environments="$1"
fi

echo Cleaning up environments under $environments
find $environments -type f -name effective.keys | xargs rm -f
find $environments -type f -name environment | xargs rm -f
find $environments -type f -name installer.iso | xargs rm -f
find $environments -type f -name installer.patch | xargs rm -f
find $environments -type f -name postinst | xargs rm -f
find $environments -type f -name preseed.cfg | xargs rm -f
find $environments -type f -name postinst-in-target | xargs rm -f
find $environments -type f -regex '.*\.qcow2' | xargs rm -f

if [ "$1" == "vm" -o "$2" == "vm" ]; then 
    vagrant destroy -f

    # For some reason the ssh tunnels for port forwarding is not cleaned up
    for port in 11888 10001 13143; do
        pid=`lsof -i :$port | egrep '^ssh.*LISTEN)$' | \
            sed -e 's/[[:space:]]*//g' | egrep -o '^ssh[0-9]*' | sed 's/ssh//' | \
            sort | uniq`
        if [ -n "$pid" ];  then
            kill -9 $pid
        fi
    done
fi