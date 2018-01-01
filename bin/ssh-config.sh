#!/bin/bash

BASE_DIR="`dirname \"$0\"`"
BASE_DIR="`( cd \"$BASE_DIR\" && pwd )`"
TOP_DIR="$BASE_DIR/.."

. $TOP_DIR/lib/general
. $TOP_DIR/lib/yaml
. $TOP_DIR/lib/settings
. $TOP_DIR/lib/load_env "$1"

# Algorithm for generating per machine authorized_keys files
# ----------------------------------------------------------
#
# Keys are collected top to bottom:
#
# 1. Check settings.xml in ${home}/.genesis-stack/settings.yml for a
#    personal authorized_keys file pointer ('add_authorized_keys')
# 2. ${path}/environments/authorized_keys
# 3. ${path}/environments/${environment}/authorized_keys
# 4. ${path}/environments/${environment}/${machine_definition}/authorized_keys
#
# The collected keys are sorted, duplicates are removed and pushed into output
# files at each level called, effective.keys, inside the environment, and the 
# machine definition directories. This is done for each machine definition by
# iterating through them all.
#

keys="$(mktemp)"

# expand out the ~/... if any
add_authorized_keys="$(eval echo $add_authorized_keys)"
if [ -n "$add_authorized_keys" -a -f "$add_authorized_keys" ]; then
  cat "$add_authorized_keys" > $keys
fi

if [ -f "$environments/authorized_keys" ]; then
  cat "$environments/authorized_keys" >> $keys
fi

if [ -f "$en_dir/authorized_keys" ]; then
  cat "$env_dir/authorized_keys" >> $keys
fi

cat "$keys" | sort | uniq > "$env_dir/effective.keys"
env_keys="$env_dir/effective.keys"

for mach_def_yml in $(find $env_dir -type f -name machine.yml); do
  mach_def_path="$(dirname $mach_def_yml)"
  keys="$(mktemp)"
  cat "$env_keys" > "$keys"
  
  if [ -f "$mach_def_path/authorized_keys" ]; then
    cat "$mach_def_path/authorized_keys" >> "$keys"
    cat "$keys" | sort | uniq > "$mach_def_path/effective.keys" 
  else
    cp "$env_keys" "$mach_def_path/effective.keys"
  fi
done

# Algorithm for generating the ssh config file
# ----------------------------------------------------------
# 
# Each machine definition is added to the config file to enable console ssh to
# every machine type as the infra user. If a valid jump host is specified then
# entries will use it: obviously not needed for testing or internal use.
#

# To be implemented later (nice to have)
