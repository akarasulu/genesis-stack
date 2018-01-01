#!/bin/bash

BASE_DIR="`dirname \"$0\"`"
BASE_DIR="`( cd \"$BASE_DIR\" && pwd )`"
TOP_DIR="$BASE_DIR/.."

. $TOP_DIR/lib/general
. $TOP_DIR/lib/yaml
. $TOP_DIR/lib/settings
. $TOP_DIR/lib/vm
. $TOP_DIR/lib/net
. $TOP_DIR/lib/services
. $TOP_DIR/lib/load_env "$1"

cat > $env_conf <<-EOF
AUTO_BUILD="$auto_build"

# Administrative account for infrastructure staff
INFRA_FULLNAME="$infra_fullname"
INFRA_ACCOUNT="$infra_account"
INFRA_PASSWORD=$INFRA_PASSWORD
INFRA_SUDOERS="$infra_sudoers"

EOF

# These cloud network values can only use $local substitutions
echo '# Cloud network settings' >> $env_conf
echo 'CLOUD_DOMAIN="'$cloud_domain'"' >> $env_conf

if [ "$(subs $cloud_network)" == "local" ]; then
  cloud_network="$(default_gw_net)"
elif [ "$(subs $cloud_network)" != "none" ]; then
  err "Invalid substitution variable $cloud_network: cloud_network can only use \$local."
  exit 20
fi
echo 'CLOUD_NETWORK="'$cloud_network'"' >> $env_conf

if [ "$(subs $cloud_netmask)" == "local" ]; then
  cloud_netmask="$(default_gw_mask)"
elif [ "$(subs $cloud_netmask)" != "none" ]; then
  err "Invalid substitution variable $cloud_netmask: cloud_netmask can only use \$local."
  exit 21
fi
echo 'CLOUD_NETMASK="'$cloud_netmask'"' >> $env_conf

if [ "$(subs $cloud_gateway)" == "local" ]; then
  cloud_gateway="$(default_gw)"
elif [ "$(subs $cloud_gateway)" != "none" ]; then
  err "Invalid substitution variable $cloud_gateway: cloud_gateway can only use \$local."
  exit 22
fi
echo 'CLOUD_GATEWAY="'$cloud_gateway'"' >> $env_conf

if [ "$(subs $cloud_dns)" == "local" ]; then
  cloud_dns="$(default_gw)" # defaulting to gw for now since we don't have a better way
elif [ "$(subs $cloud_dns)" != "none" ]; then
  err "Invalid substitution variable $cloud_dns: cloud_dns can only use \$local."
  exit 23
fi
echo 'CLOUD_DNS="'$cloud_dns'"' >> $env_conf

echo 'USE_DHCP="'$use_dhcp'"' >> $env_conf
echo 'CEPH_AVAILABLE="'$ceph_available'"' >> $env_conf

echo >> $env_conf
echo '# Ansilary infrastructure services' >> $env_conf

dns_server="$cloud_dns"
local_addr="$(default_gw_dev_ip)"
vm_addr="$local_addr"

dns_addr="$(find_dns $dns_server approx)"
approx_std_port='9999'
approx_vm_port='10001'
if [ "$(subs $approx_host)" == "local" -o "$(subs $approx_host)" == "local_first" ]; then
  if [ -n "$dns_addr" -a "$(check_approx $dns_addr $approx_std_port)" == "up" ]; then
    approx_host="$dns_addr"
    approx_port="$approx_std_port"
  elif [ "(check_approx $local_addr $approx_std_port)" ]; then
    approx_host="$local_addr"
    approx_port="$approx_std_port"
  elif [ "$(subs $approx_host)" == "local_first" ]; then
    approx_host="$vm_addr"
    approx_port="$approx_vm_port"
  else
    err "Local approx service not found. Searched dns and local host."
    exit 30
  fi
elif [ "$(subs $approx_host)" == "vm" -o "$(subs $approx_host)" == "vm_first" ]; then
    approx_host="$vm_addr"
    approx_port="$approx_vm_port"
fi
echo 'APPROX_HOST="'$approx_host'"' >> $env_conf
echo 'APPROX_PORT="'$approx_port'"' >> $env_conf


dns_addr="$(find_dns $dns_server acng)"
acng_std_port='3142'
acng_vm_port='13143'
if [ "$(subs $acng_host)" == "local" -o "$(subs $acng_host)" == "local_first" ]; then
  if [ -n "$dns_addr" -a "$(check_acng $dns_addr $acng_std_port)" == "up" ]; then
    acng_host="$dns_addr"
    acng_port="$acng_std_port"
  elif [ "(check_acng $local_addr $acng_std_port)" ]; then
    acng_host="$local_addr"
    acng_port="$acng_std_port"
  elif [ "$(subs $acng_host)" == "local_first" ]; then
    acng_host="$vm_addr"
    acng_port="$acng_vm_port"
  else
    err "Local acng service not found. Searched dns and local host."
    exit 31
  fi
elif [ "$(subs $acng_host)" == "vm" -o "$(subs $acng_host)" == "vm_first" ]; then
    acng_host="$vm_addr"
    acng_port="$acng_vm_port"
fi
echo 'ACNG_HOST="'$acng_host'"' >> $env_conf
echo 'ACNG_PORT="'$acng_port'"' >> $env_conf

dns_addr="$(find_dns $dns_server configs)"
configs_std_port='80'
configs_vm_port='11888'
if [ "$(subs $configs_host)" == "local" -o "$(subs $configs_host)" == "local_first" ]; then
  if [ -n "$dns_addr" -a "$(check_configs $dns_addr $configs_std_port)" == "up" ]; then
    configs_host="$dns_addr"
    configs_port="$configs_std_port"
  elif [ "(check_configs $local_addr $configs_std_port)" ]; then
    configs_host="$local_addr"
    configs_port="$configs_std_port"
  elif [ "$(subs $configs_host)" == "local_first" ]; then
    configs_host="$vm_addr"
    configs_port="$configs_vm_port"
  else
    err "Local configs service not found. Searched dns and local host."
    exit 32
  fi
elif [ "$(subs $configs_host)" == "vm" -o "$(subs $configs_host)" == "vm_first" ]; then
    configs_host="$vm_addr"
    configs_port="$configs_vm_port"
fi
echo 'CONFIGS_HOST="'$configs_host'"' >> $env_conf
echo 'CONFIGS_PORT="'$configs_port'"' >> $env_conf

dns_addr="$(find_dns $dns_server ntp)"
if [ "$(subs $ntp_host)" == "local" ]; then
  if [ -n "$dns_addr" -a "$(check_ntp $dns_addr)" == "up" ]; then
    ntp_host="$dns_addr"
  elif [ "(check_ntp $local_addr)" ]; then
    ntp_host="$local_addr"
  else
    err "Local ntp service not found. Searched dns and local host."
    exit 33
  fi
elif [ "$(subs $ntp_host)" != "none" ]; then
  err "Invalid substitution variable $ntp_host: ntp_host can only use \$local."
  exit 24
fi
echo 'NTP_HOST="'$ntp_host'"' >> $env_conf


dns_addr="$(find_dns $dns_server cdn)"
if [ "$(subs $cdn_host)" == "local" ]; then
  if [ -n "$dns_addr" -a "$(check_cdn $dns_addr 8338)" == "up" ]; then
    cdn_host="$dns_addr"
  elif [ "(check_cdn $local_addr 8338)" ]; then
    cdn_host="$local_addr"
  else
    err "Local cdn service not found. Searched dns and local host."
    exit 33
  fi
elif [ "$(subs $cdn_host)" != "none" ]; then
  err "Invalid substitution variable $cdn_host: cdn_host can only use \$local."
  exit 24
fi
echo 'CDN_HOST="'$cdn_host'"' >> $env_conf


cat >> $env_conf <<-EOF
IMAGES_HOST="$vm_addr"
ANSIBLE_HOST="$vm_addr"
JUMP_HOST="$vm_addr"
JENKINS_HOST="$vm_addr"
KEYS_HOST="$configs_host"
KEYS_PORT="$configs_port"
KEYS_PATH="$keys_path"

EOF

# Add last empty line
echo >> $env_conf
