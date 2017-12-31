#!/bin/bash

function usage() {
    echo
    echo "Creates a multi-purpose (medium) ISO installer for a machine"
    echo "definition or all machine definitions within an environment."
    echo
    echo "test-iso <environment> [<machine> ]*"
    echo
    echo "   environment:"
    echo "     a valid environment within the environments directory"
    echo "   [<machine> ]*:"
    echo "     an optional list of zero or more space delimited machine"
    echo "     definition names to build rather than building all the machines"
    echo "     defined in the environment"
    echo
}

BASE_DIR="`dirname \"$0\"`"
BASE_DIR="`( cd \"$BASE_DIR\" && pwd )`"
TOP_DIR="$BASE_DIR/.."

. $TOP_DIR/lib/general
. $TOP_DIR/lib/yaml
. $TOP_DIR/lib/settings
. $TOP_DIR/lib/load_env_mach "$1" "$2"

    
cd installer/build
echo 'PRESEED=/vagrant/environments/'$env_name/$mach_def'/preseed.cfg' > config/local
echo 'USE_UDEBS_FROM=stretch' >> config/local
fakeroot make rebuild_netboot

cp 'dest/netboot/mini.iso' "/vagrant/environments/$env_name/$mach_def/installer.iso"
