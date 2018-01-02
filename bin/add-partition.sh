#!/bin/bash

BASE_DIR="`dirname \"$0\"`"
BASE_DIR="`( cd \"$BASE_DIR\" && pwd )`"
TOP_DIR="$BASE_DIR/.."

. $TOP_DIR/lib/general
. $TOP_DIR/lib/yaml
. $TOP_DIR/lib/settings
. $TOP_DIR/lib/load_env_mach "$1" "$2"

iso="$mach_def_path/installer.iso"
target="$(mktemp)"

qemu-img convert -O qcow2 "$iso" "$target"
qemu-img resize "$target" +2G
sudo qemu-nbd --connect=/dev/nbd6 "$target"
echo "n
p


w
"|sudo fdisk /dev/nbd6
sudo mkfs.ext4 /dev/nbd6p4
sudo dd if=/dev/nbd6 bs=10M | gzip > $iso.gz 
rm $iso
sudo qemu-nbd --disconnect /dev/nbd6
cp "$target" "$mach_def_path/usb-drive.qcow2"


