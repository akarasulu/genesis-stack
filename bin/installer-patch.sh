#!/bin/bash

BASE_DIR="`dirname \"$0\"`"
BASE_DIR="`( cd \"$BASE_DIR\" && pwd )`"
TOP_DIR="$BASE_DIR/.."

. $TOP_DIR/lib/general
. $TOP_DIR/lib/yaml
. $TOP_DIR/lib/settings
. $TOP_DIR/lib/load_env_mach "$1" "$2"

# TODO wget from URL build path based on machine definition
uri_path='/environments/'$env_name'/'$mach_def'/'preseed.cfg
url='http://'$CONFIGS_HOST':'"$CONFIGS_PORT""$uri_path"
local_Path=$mach_def_path'/'postinst

cat installer.patch | sed -e "s@\${PRESEED_URL}@$url@" > "$mach_def_path/installer.patch"
