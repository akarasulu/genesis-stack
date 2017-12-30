#!/bin/bash

# ARGS: $1 the machine hardware profile name (i.e. pvms-compute-1) 
# ARGS: $2 the environment name (i.e. kg.cloud) 
# ARGS: $3 optional installer.iso override 
# INPUTS: the machine definition YAML files in machine def directories

BASE_DIR="`dirname \"$0\"`"
BASE_DIR="`( cd \"$BASE_DIR\" && pwd )`"
TOP_DIR="$BASE_DIR/../../"

. $TOP_DIR/machines/scripts/libs/funcs
. $TOP_DIR/machines/scripts/libs/yaml

function usage_info() {
    echo
    echo "Creates a virtual machine with disks and interfaces to test the"
    echo "installer."
    echo
    echo "test-iso <machine> <environment>"
    echo
    echo "   machine:"
    echo "     a valid (virtual|physical) machine definition directory"
    echo "   environment:"
    echo "     a valid environment directory with configuration files"
    echo
}

mach_def="$1"
mach_def_path=''
is_virtual=''

envconf="$2"
envconf_dir="$TOP_DIR/environments/$envconf"
envconf_file="$TOP_DIR/environments/$envconf/environment"

if [ -n "$mach_def" ]; then
  physical_path="$TOP_DIR/machines/physical/$mach_def"
  virtual_path="$TOP_DIR/machines/virtual/$mach_def"

  if [ -d "$virtual_path" -a -d "$physical_path" ]; then
    echo_err "WTF! The machine exists as both physical and virtual."
    usage_info; exit 10
  elif [ -d "$physical_path" ]; then
    is_virtual='false'
    mach_def_path="$physical_path"
  elif [ -d "$virtual_path" ]; then
    is_virtual='true'
    mach_def_path="$virtual_path"
  else
    echo_err "The machine directory for $mach_def does not exist"
    echo_err "Tried the following paths:"
    echo_err "    ->  [virtual] $physical_path"
    echo_err "    -> [physical] $virtual_path"
    usage_info; exit 11
  fi

  nics_dbf="$mach_def_path/nics.yml"
  if [ ! -f $nics_dbf ]; then
    echo_err "Network card db file $nics_dbf does not exist for $mach_def"
    usage_info; exit 12
  fi

  mach_dbf="$mach_def_path/machine.yml"
  if [ ! -f "$mach_dbf" ]; then
    echo_err "Machine db file $mach_dbf does not exist for $mach_def"
    usage_info; exit 13
  fi

  drives_dbf="$mach_def_path/drives.yml"
  if [ ! -f "$drives_dbf" ]; then
    echo_err "Drive db file $drives_dbf does not exist for $mach_def"
    usage_info; exit 14
  fi
else
  echo_err "No valid machine definition name was provided."
  usage_info; exit 1
fi

if [ -n "$envconf" ]; then
  if [ ! -d "$envconf_dir" ]; then
    echo_err "Environment directory for $envconf does not exist"
    usage_info; exit 20
  elif [ ! -f "$envconf_file" ]; then
    echo_err "No environment file found for $envconf"
    usage_info; exit 21
  fi

  . "$envconf_file"
else
  echo_err "No valid environment name was provided."
  usage_info; exit 2
fi

cpus=`cat $mach_dbf | grep cpus: | awk '{print $2}'`
ram=`cat $mach_dbf | grep ram: | awk '{print $2}'`

declare -a drives


drive_count=$(count "$drives_dbf")
ii=0
while [ $ii -lt 6 ]; do
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

index=0
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
    # $devices -device e1000,netdev=virbr0,mac=$mac -netdev tap,id=virbr0         \
    -fsdev local,security_model=passthrough,id=fsdev0,path=$TOP_DIR             \
    -device virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare
elif [ -n "$3" -a -f "$3" ]; then
  installer="$3"

  qemu-system-x86_64 -enable-kvm -m $ram                                        \
    -boot d -cdrom $installer                                                   \
    -device virtio-scsi-pci,id=scsi                                             \
    $devices
else
installer="$TOP_DIR/machines/physical/images/debian-9.1-amd64-CD-1.iso"
  qemu-system-x86_64 -enable-kvm -m $ram                                        \
    -boot d -cdrom $installer                                                   \
    -device virtio-scsi-pci,id=scsi                                             \
    $devices -net nic -net bridge,br=br0                                        \
    -fsdev local,security_model=passthrough,id=fsdev0,path=$TOP_DIR             \
    -device virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare
fi

