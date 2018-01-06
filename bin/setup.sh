#!/bin/bash

BASE_DIR="`dirname \"$0\"`"
BASE_DIR="`( cd \"$BASE_DIR\" && pwd )`"
TOP_DIR="$BASE_DIR/.."

if [ -z "$TOP_DIR" ]; then
  TOP_DIR="$BASE_DIR"
fi

. $TOP_DIR/lib/general
. $TOP_DIR/lib/yaml
. $TOP_DIR/lib/settings
. $TOP_DIR/lib/vm

if [ -z "$(echo $PATH | grep 'genesis-stack/bin')" ]; then
  echo "Adding base genesis-stack to path."
  echo "Stop this message in new terminals. Put this into your profile:"
  echo "export PATH=$PATH:$TOP_DIR/bin"
  export PATH=$TOP_DIR/bin
fi

if [ ! -f "$overrides" ]; then
  echo "No overrides directy setup: $overrides"
  echo "This might present problems in development mode with the virtual machine."
fi

if [ "$environments" == "$TOP_DIR/environments" ]; then
  echo "Using embedded ./environments directory containing mock environments."
fi

if [ ! -d "$environments" ]; then
  echo "Environments directory does not exist: $environments"
  echo "This will certainly cause problems."
  echo "Check in $overrides/settings.yml to make sure it points to the correct path."
fi

# TODO: check for libvirt
# TODO: check for vagrant-libvirt
# TODO: check for vagrant
# TODO: check for proper networking setup
# TODO: check for bridge device on local machine

echo "Cleaning up past runs ..."
echo "    => " $(cleanup.sh)
echo "Firing up virtual machine ..."
echo "    => "
vm_run
