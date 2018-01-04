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
if [ ! $? -eq 0 ]; then
  echo "Failed while generating keys and ssh-config files."
  exit $?
fi

echo "Generating preseed.cfg file ..."
. $TOP_DIR/bin/stretch-preseed.sh "$1" "$2"
if [ ! $? -eq 0 ]; then
  echo "Failed while generating preseed.cfg file."
  exit $?
fi

echo "Applying installer patch ..."
. $TOP_DIR/bin/installer-patch.sh "$1" "$2"
if [ ! $? -eq 0 ]; then
  echo "Failed while applying installer patch."
  exit $?
fi

echo "Generating postinst file ..."
. $TOP_DIR/bin/postinst.sh "$1" "$2"
if [ ! $? -eq 0 ]; then
  echo "Failed while generating postinst file."
  exit $?
fi

echo "Generating postinst-in-target file ..."
. $TOP_DIR/bin/postinst-in-target.sh "$1" "$2"
if [ ! $? -eq 0 ]; then
  echo "Failed while generating postinst-in-target file."
  exit $?
fi

echo "Generating post-partition script"
$TOP_DIR/bin/post-partition.sh "$1" "$2"
if [ ! $? -eq 0 ]; then
  echo "Failed generating the post-partition scripts."
  exit $?
fi

echo "Checking and starting virtual machine ..."
vm_run  3>&1 1>&2 2>&3 3>&- | grep -v nokogiri
if [ ! $? -eq 0 ]; then
  echo "Failed to bring the virtual machine to a running state."
  exit $?
fi

echo "Building ISO installer ..."
pushd .
cd $TOP_DIR
vagrant ssh -c "/var/www/html/code/bin/vagrant-build.sh $env_name $mach_def" 3>&1 1>&2 2>&3 3>&- | grep -v nokogiri
if [ ! $? -eq 0 ]; then
  echo "Failed while building ISO installer in the virtual machine."
  exit $?
fi
popd

echo "Adding extra partition to ISO file and USB virtual drive."
$TOP_DIR/bin/add-partition.sh "$1" "$2"
