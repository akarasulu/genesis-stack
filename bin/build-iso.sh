#!/bin/bash

BASE_DIR="`dirname \"$0\"`"
BASE_DIR="`( cd \"$BASE_DIR\" && pwd )`"
TOP_DIR="$BASE_DIR/.."

. $TOP_DIR/lib/general
. $TOP_DIR/lib/yaml
. $TOP_DIR/lib/settings

echo "Generating environment configuration files ..."
$TOP_DIR/bin/environment.sh "$1"

. $TOP_DIR/lib/load_env_mach "$1" "$2"
. $TOP_DIR/lib/vm

echo "Generating keys and ssh-config files ..."
. $TOP_DIR/bin/ssh-config.sh "$1"
echo "Generating preseed.cfg file ..."
. $TOP_DIR/bin/stretch-preseed.sh "$1" "$2"
echo "Generating installer.patch file ..."
. $TOP_DIR/bin/installer-patch.sh "$1" "$2"
echo "Generating postinst file ..."
. $TOP_DIR/bin/postinst.sh "$1" "$2"
echo "Generating postinst-in-target file ..."
. $TOP_DIR/bin/postinst-in-target.sh "$1" "$2"

echo "Checking and starting virtual machine ..."
vm_run
echo "Building ISO installer ..."
vagrant ssh -c "/vagrant/bin/vagrant-build.sh $env_name $mach_def"
