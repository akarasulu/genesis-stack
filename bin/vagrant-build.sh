#!/bin/bash

function usage() {
    echo
    echo "Creates a multi-purpose (medium) ISO installer for one or more"
    echo "machine definitions or all within an environment. This script is"
    echo "intended to be executed on an image builder machine."
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

# Start fresh from scratch every time
rm -rf installer
apt-get source -y debian-installer
mv `find . -maxdepth 1 -type d -regex '^./debian-installer-2.*'` installer

# Patch the installer with the customized machine patch
patch -R -p0 < "/var/www/html/environments/$env_name/$mach_def/installer.patch"

# Prepare the installer
cd installer/build
echo 'PRESEED=/var/www/html/environments/'$env_name/$mach_def'/preseed.cfg' > config/local
echo 'USE_UDEBS_FROM=stretch' >> config/local

udebs='/var/www/html/environments/'$env_name/$mach_def'/udebs'
if [ -f "$udebs" ]; then
  cat "$udebs" >> pkg-lists/local
fi 

fakeroot make rebuild_netboot

cp 'dest/netboot/mini.iso' "/var/www/html/environments/$env_name/$mach_def/installer.iso"
