#!/bin/sh

BASE_DIR="`dirname \"$0\"`"
BASE_DIR="`( cd \"$BASE_DIR\" && pwd )`"
TOP_DIR="$BASE_DIR/.."

. $TOP_DIR/lib/general
. $TOP_DIR/lib/yaml
. $TOP_DIR/lib/settings
. $TOP_DIR/lib/load_env_mach "$1" "$2"

# TODO wget from URL build path based on machine definition
uri_path='/'$env_name'/'$mach_def'/'postinst
url='http://'$HTTP_HOST':'"$HTTP_PORT""$uri_path"
local_Path=$mach_def_path'/'postinst

cat > $local_Path <<-EOF
#!/bin/sh

while true; do
  if [ -f "/stop" ]; then
    rm /stop
    break;
  fi

  sleep 1
done

EOF
