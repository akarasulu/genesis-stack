#!/bin/bash

BASE_DIR="`dirname \"$0\"`"
BASE_DIR="`( cd \"$BASE_DIR\" && pwd )`"
TOP_DIR="$BASE_DIR/.."

. $TOP_DIR/lib/general
. $TOP_DIR/lib/yaml
. $TOP_DIR/lib/disk

. $TOP_DIR/lib/settings
. $TOP_DIR/lib/load_env_mach "$1" "$2"

script="$mach_def_path/post-partition"
strategy="$environments/disk-strategy.yml"
drives="$mach_def_path/drives.yml"

count=$(count $drives)

declare -a all_drives
declare -a ssd_drives
declare -A capacities
declare -a hdd_drives

ii=0
while [ $ii -lt $count ]; do
  rec "$ii" "$drives"
  if [ "$is_rotational" == "true" ]; then
    hdd_drives+=("$deviceId")
  else
    ssd_drives+=("$deviceId")
  fi

  all_drives+=("$deviceId")
  debug "all_drives = ${all_drives[@]}"
  debug "all_drives size = ${#all_drives[@]}"
  capacities+=(["$deviceId"]="$capacity")
  ((ii++))
done

ii=0
count="$(count $strategy)"
# Loads disks, ssds, hdds, ceph, md0, md1, sys, data, ratio, var_home, vm, contrib
while [ $ii -lt $count ]; do
  pat='^disks[[:space:]]+: '"${#all_drives[@]}"'$'
  rec "$ii" "$strategy" "$pat"
  if [ $disks -eq ${#all_drives[@]} -a $ssds -eq ${#ssd_drives[@]} -a $hdds -eq ${#hdd_drives[@]} ]; then
    if [ "$ceph" == "$ceph_available" ]; then
      break;
    fi
  fi
  ((ii++))
done

md0_disk_set=''
md1_disk_set=''

cat > $script <<-EOF
#!/bin/sh

if [ ! -f /preseed.cfg ]; then
  err "Not in the Debian Install environment. Exiting .."
fi

export DEBUG="$debug"

# Constants
code_dir='/genesis-stack/code'
libs_dir="\$code_dir/lib"
bins_dir="\$code_dir/bin"
base_dir='/genesis-stack/environments'
env_dir="\$base_dir/$env_name"
mach_dir="\$env_dir/$mach_def"

# Load libraries

. "\$libs_dir/general"
. "\$libs_dir/yaml"
. "\$libs_dir/disk"

# Find values for installation
boot_part="\$(boot_partition)"

# Let's presume if we cannot detect (we know installer does this)
if [ -z "\$boot_part" ]; then
  boot_part='/dev/sda1'
fi

boot_drive="\$(boot_drive)"
if [ -z "\$boot_drive" ]; then
  boot_drive='/dev/sda'
fi

boot_sectors="\$(fdisk -s \$boot_part)"
boot_size=\$((boot_sectors * 2))

# Selected strategy variables
disks=$disks
ssds=$ssds
hdds=$hdds
ceph="$ceph_available"
md0="$md0"
md1="$md1"
sys="$sys"
data="$data"
ratio="$ratio"
var_home="$var_home"
vm="$vm"
contrib="$contrib"

debug_step postinst_parts_remove

# wipe the LVM partitions
unmount_fs
wipe_lvm

debug_step postinst_parts_create

EOF

#
# One Drive
#

if [ "${#all_drives[@]}" -eq 1 ]; then
  exp_drive_dev_id="${all_drives[0]}"
  exp_drive_capacity="${capacities[$exp_drive_dev_id]}"

  cat >> $script <<-EOF
exp_total_drive_count=1
exp_drive_dev_id="$exp_drive_dev_id"
exp_drive_capacity="$exp_drive_capacity"

EOF
  cat $TOP_DIR/bin/one-drive >> $script
  cat $TOP_DIR/bin/logical_volumes >> $script
  exit 0
fi

#
# Two Drives: NO RAID
#

if [ ${#all_drives[@]} -eq 2 -a "$md0" == "no" -a "$md1" == "no" ]; then
  # Presuming the smaller drive is the SSD for Sys
  if [ ${capacities[all_drives[0]]} -lt ${capacities[all_drives[1]]} ]; then
    exp_sys_drive_dev_id="${all_drives[0]}"
    exp_sys_drive_capacity="${capacities[$exp_sys_drive_dev_id]}"

    exp_data_drive_dev_id="${all_drives[1]}"
    exp_data_drive_capacity="${capacities[$exp_data_drive_dev_id]}"
  else
    exp_sys_drive_dev_id="${all_drives[1]}"
    exp_sys_drive_capacity="${capacities[$exp_sys_drive_dev_id]}"

    exp_data_drive_dev_id="${all_drives[0]}"
    exp_data_drive_capacity="${capacities[$exp_data_drive_dev_id]}"
  fi

  cat >> $script <<-EOF
exp_total_drive_count=2
exp_sys_drive_dev_id="$exp_sys_drive_dev_id"
exp_sys_drive_capacity="$exp_sys_drive_capacity"

exp_data_drive_dev_id="$exp_data_drive_dev_id"
exp_data_drive_capacity="$exp_data_drive_capacity"
EOF
  cat $TOP_DIR/bin/two-drives >> $script
  cat $TOP_DIR/bin/logical_volumes >> $script
  exit 0
fi

# 
# Two RAID Sets
# 

# having both md0 and md1 means we have raid for ssd and hdd
if [ "$md0" != "no" -a "$md1" != "no" ]; then

  for drive in "${ssd_drives[@]}"; do
    exp_md0_drives="$exp_md0_drives $drive"
    exp_md0_drive_sizes=${capacities[$drive]}
  done

  exp_md0_drives="$(echo $exp_md0_drives | sed -e 's/^ //')"
  exp_md0_drive_count="${#ssd_drives[@]}"
  exp_md0_drive_set="$exp_md0_drive_sizes $exp_md0_drive_count $(echo $exp_md0_drives | sed -e 's/ /,/g')"


  for drive in "${hdd_drives[@]}"; do
    exp_md1_drives="$exp_md1_drives $drive"
    exp_md1_drive_sizes=${capacities[$drive]}
  done

  exp_md1_drives="$(echo $exp_md1_drives | sed -e 's/^ //')"
  exp_md1_drive_count="${#hdd_drives[@]}"
  exp_md1_drive_set="$exp_md1_drive_sizes $exp_md1_drive_count $(echo $exp_md1_drives | sed -e 's/ /,/g')"

  exp_total_drive_count="${#all_drives[@]}"

  cat >> $script <<-EOF
# These are the expected disks
exp_md0_drive_set="$exp_md0_drive_set"
exp_md0_drive_count="$exp_md0_drive_count"
exp_md0_drive_sizes="$exp_md0_drive_sizes"
exp_md0_drives="$exp_md0_drives"

exp_md1_drive_set="$exp_md1_drive_set"
exp_md1_drive_count="$exp_md1_drive_count"
exp_md1_drive_sizes="$exp_md1_drive_sizes"
exp_md1_drives="$exp_md1_drives"

exp_total_drive_count="$exp_total_drive_count"

EOF

  cat $TOP_DIR/bin/two-raid-sets                    >> $script
  cat $TOP_DIR/bin/logical_volumes                  >> $script

  exit 0
fi

# 
# One RAID Set
#

if [ "$md0" != "no" ]; then
  if [ $ssds -gt 1 ]; then
    for drive in "${ssd_drives[@]}"; do
      exp_md0_drives="$exp_md0_drives $drive"
      exp_md0_drive_sizes=${capacities[$drive]}
    done

    exp_md0_drive_count="${#ssd_drives[@]}"
    exp_md0_drive_set="$exp_md0_drive_sizes $exp_md0_drive_count $(echo $exp_md0_drives | sed -e 's/ /,/g')"
    exp_other_drive="${hdd_drives[0]}"
    exp_other_drive_size="${capacities[$other_drive]}"
  elif [ $hdds -gt 1 ]; then
    for drive in "${hdd_drives[@]}"; do
      exp_md0_drives="$exp_md0_drives $drive"
      exp_md0_drive_sizes="${capacities[$drive]}"
    done

    exp_md0_drive_count="${#hdd_drives[@]}"
    exp_md0_drive_set="$exp_md0_drive_sizes $exp_md0_drive_count $(echo $exp_md0_drives | sed -e 's/ /,/g')"
    exp_other_drive="${ssd_drives[0]}"
    exp_other_drive_size="${capacities[$other_drive]}"
  else
    err "Illegal state: we should have at least one raid set!"
    exit 10
  fi

  cat $TOP_DIR/bin/one-raid-set                     >> $script
  cat $TOP_DIR/bin/logical_volumes                  >> $script

  exit 0
fi
