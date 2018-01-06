#!/bin/bash

# ARGS: $1 the machine hardware profile name (i.e. pvms-compute-1) 
# ARGS: $2 the environment name (i.e. kg.cloud) 
# ARGS: $3 optional installer.iso override 
# INPUTS: the machine definition YAML files in machine def directories

BASE_DIR="`dirname \"$0\"`"
BASE_DIR="`( cd \"$BASE_DIR\" && pwd )`"
TOP_DIR="$BASE_DIR/.."

. $TOP_DIR/lib/general
. $TOP_DIR/lib/yaml

function usage_info() {
    echo
    echo "Fires up test virtual machines with disks and interfaces to test the"
    echo "installer."
    echo
    echo "test-iso <environment> [<machine> ]*"
    echo
    echo "   environment:"
    echo "     a valid environment with configuration files"
    echo "   machine:"
    echo "     a list of zero or more machine definitions"
    echo
}

. $TOP_DIR/lib/settings
. $TOP_DIR/lib/load_env_mach "$1" "$2"

cpus=`cat $mach_dbf | grep cpus: | awk '{print $2}'`
ram=`cat $mach_dbf | grep ram: | awk '{print $2}'`

declare -a drives

drive_count=$(count "$drives_dbf")

debug "drive_count = $drive_count"
debug "mach_def_path = $mach_def_path"

ii=0
while [ $ii -lt $drive_count ]; do
  rec "$ii" "$drives_dbf"
  if [ "$is_rotational" == "true" ]; then
    image="$mach_def_path/hdd-$deviceId.qcow2"
  else 
    image="$mach_def_path/ssd-$deviceId.qcow2"
  fi

  if [ "$3" == "boot" ]; then
    echo 'Will be booting, will not recreate drive image '$image
  else
    qemu-img create -f qcow2 "$image" "$capacity"'M'
  fi

  drives+=("$image")
  ((ii++))
done

debug "drives collected = ${#drives[@]}"

index=1
devices=''
for ii in "${!drives[@]}"; do
  img="${drives[$ii]}"
  dev=`echo $img | sed -e 's/.*\(ssd\|hdd\)-//' -e 's/\.qcow2$//'`
  devices=$devices' -device scsi-hd,drive='$dev
  devices=$devices' -drive if=none,id='$dev',file='"${drives[$ii]}"
  if [ "$3" == "boot" ]; then
    devices=$devices',boot=on'
  fi
  devices=$devices',media=disk,snapshot=off,format=qcow2,index='$index
  ((index++))
done

# How to mount shared host file system inside guest:
# --------------------------------------------------
# mkdir /tmp/host_files
# mount -t 9p -o trans=virtio,version=9p2000.L hostshare /tmp/host_files

# The optional installer image override
mac=`printf '52:54:00:EF:%02X:%02X\n' $((RANDOM%256)) $((RANDOM%256))`
if [ "$3" == "boot" ]; then
  qemu-system-x86_64 -enable-kvm -m $ram                                        \
    -device virtio-scsi-pci,id=scsi                                             \
    $devices -net nic -net bridge,br=br0                                        \
    -fsdev local,security_model=passthrough,id=fsdev0,path=$TOP_DIR             \
    -device virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare
elif [ -n "$3" -a -f "$3" ]; then
  installer="$3"

  qemu-system-x86_64 -enable-kvm -m $ram                                        \
    -boot d -cdrom $installer                                                   \
    -device virtio-scsi-pci,id=scsi                                             \
    $devices -net nic -net bridge,br=br0 
else
usb_image="$mach_def_path/usb-drive.qcow2"
usb_dev='sdz'

  qemu-system-x86_64 -enable-kvm -m $ram -usb                                   \
    -boot menu=on                                                               \
    -drive if=none,id=$usb_dev,file=$usb_image,boot=on,index=0                  \
    -device usb-ehci,id=ehci                                                    \
    -device usb-storage,bus=ehci.0,drive=$usb_dev                               \
    -device virtio-scsi-pci,id=scsi                                             \
    $devices -net nic -net bridge,br=br0                                        \
    -fsdev local,security_model=passthrough,id=fsdev0,path=$TOP_DIR             \
    -device virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare
fi

