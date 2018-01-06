#!/bin/bash

BASE_DIR="`dirname \"$0\"`"
BASE_DIR="`( cd \"$BASE_DIR\" && pwd )`"
TOP_DIR="$BASE_DIR/.."

. $TOP_DIR/lib/general
. $TOP_DIR/lib/yaml
. $TOP_DIR/lib/settings
. $TOP_DIR/lib/load_env_mach "$1" "$2"

# TODO wget from URL build path based on machine definition
mach_uri='environments/'$env_name'/'$mach_def
net_uri="code/lib/net"

base_url='http://'$CONFIGS_HOST':'"$CONFIGS_PORT"
net_url="$base_url/$net_uri"
mach_url="$base_url/$mach_uri"
local_path=$mach_def_path'/'postinst

cat > $local_path <<-EOF
#!/bin/sh

export DEBUG="$debug"

debug_step () {
  local lock_file="/tmp/debug.\$1"
  local message_file="/tmp/debug.\$1"'.message'

  if [ "\$DEBUG" != 'enabled' ]; then
    return 0
  fi

  rm -f "\$lock_file"
  rm -f "\$message_file"
  echo "[DEBUG] blocking waiting for \'touch \$lock_file\'" > "\$message_file"

  if [ -n "\$2" ]; then
    echo "[DEBUG] \$2" >> "\$message_file"
  fi

  while true; do
    if [ -f "\$lock_file" ]; then
      rm "\$lock_file"
      rm "\$message_file"
      break;
    fi

    sleep 1
  done
}

if [ "\$1" == "skip" ]; then
  echo "Skipping first debug point"
else
  debug_step postinst_init
fi

wget "$net_url"
. ./net
dl_code "$base_url"
dl_def "$base_url" "$env_name" "$mach_def"
rm ./net

. '/genesis-stack/code/lib/general'
# . '/genesis-stack/code/lib/settings'
. '/genesis-stack/code/lib/yaml'
. '/genesis-stack/code/lib/disk'
. '/genesis-stack/code/lib/net'

debug_step postinst_dokeys

# 4th USB drive partition for backup (created in process)
back2usb

# Copy over effective keys for the infra user
mkdir -p /mnt/root/home/$INFRA_ACCOUNT/.ssh
cp /genesis-stack/environments/$env_name/$mach_def/effective.keys /mnt/root/home/$INFRA_ACCOUNT/.ssh/authorized_keys
chmod -R 0600 /mnt/root/home/$INFRA_ACCOUNT/.ssh
chown -R 1000:1000 /mnt/root/home/$INFRA_ACCOUNT/.ssh

debug_step postinst_start_partitioning

# Execute the partitioning plan
chmod +x /genesis-stack/environments/$env_name/$mach_def/post-partition
/genesis-stack/environments/$env_name/$mach_def/post-partition

debug_step postinst_finish

EOF
