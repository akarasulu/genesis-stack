#!/bin/bash

BASE_DIR="`dirname \"$0\"`"
BASE_DIR="`( cd \"$BASE_DIR\" && pwd )`"
TOP_DIR="$BASE_DIR/.."

. $TOP_DIR/lib/general
. $TOP_DIR/lib/yaml
. $TOP_DIR/lib/settings
. $TOP_DIR/lib/load_env_mach "$1" "$2"

preseed_path="$mach_def_path/preseed.cfg"

# Simple Parameters

if [ -z "$LOCALES" ]; then
    LOCALES='en_US en_US.UTF-8'
fi

if [ -z "$COUNTRY" ]; then
    COUNTRY='US'
fi

if [ -z "$LANGUAGE" ]; then
    LANGUAGE='en'
fi

# Associated with our scheme

## TODO do this from all sourced environment variables
if [ -z "$DEBUG" ]; then
    DEBUG='true'
fi

## TODO can enable per machine definition keys file?
AUTHORIZED_KEYS_URL='http://'$KEYS_HOST':'$KEYS_PORT'/'$env_name$KEYS_PATH

ENABLE_NETCON="$DEBUG"

cat > $preseed_path <<-EOF
d-i debconf/priority                   select critical
d-i auto-install/enabled               boolean true

EOF

if [ "$ENABLE_NETCON" == "true" ]; then
cat >> $preseed_path <<-EOF

# Net console
d-i anna/choose_modules string network-console
d-i preseed/early_command string anna-install network-console
d-i network-console/password-disabled boolean true
d-i network-console/authorized_keys_url string $AUTHORIZED_KEYS_URL

EOF
fi

cat >> $preseed_path <<-EOF

# Account setup
d-i passwd/root-login boolean false
d-i passwd/user-fullname string $INFRA_FULLNAME
d-i passwd/username string $INFRA_ACCOUNT
d-i passwd/user-password password $INFRA_PASSWORD
d-i passwd/user-password-again password $INFRA_PASSWORD
d-i user-setup/encrypt-home boolean false
d-i user-setup/allow-password-weak boolean true

# Locale setup
d-i debian-installer/country string $COUNTRY
d-i debian-installer/language string $LANGUAGE
EOF

for locale in $LOCALES; do
    echo 'd-i debian-installer/locale string '$locale >> $preseed_path
done

cat >> $preseed_path <<-EOF

# Keyboard
d-i console-setup/ask_detect boolean false
d-i console-setup/layoutcode string us
d-i console-setup/variantcode string
d-i keyboard-configuration/layoutcode string us

# Clock and time zone setup
d-i clock-setup/utc boolean true
d-i time/zone string UTC
d-i clock-setup/ntp boolean true

# Need conditional check to determine if ntp server is available
d-i clock-setup/ntp-server string $NTP_HOST
EOF

if [ "$USE_DHCP" == "true" ]; then
cat >> $preseed_path <<-EOF

# Network Conifgurations
d-i netcfg/choose_interface select auto
d-i netcfg/disable_dhcp                boolean false
d-i netcfg/confirm_static              boolean false
d-i netcfg/get_hostname                string $mach_def
d-i netcfg/get_domain                  string $CLOUD_DOMAIN
EOF
else
# TODO: need to figure out hash to use on mach_def name to
# get a unique IP address for each machine on the network?
cat >> $preseed_path <<-EOF

# Network Conifgurations
d-i netcfg/choose_interface select auto
d-i netcfg/disable_dhcp                boolean true
d-i netcfg/get_nameservers             string $CLOUD_DNS
d-i netcfg/get_ipaddress               string 172.16.1.212
d-i netcfg/get_netmask                 string $CLOUD_NETMASK
d-i netcfg/get_gateway                 string $CLOUD_GATEWAY
d-i netcfg/confirm_static              boolean true
d-i netcfg/get_hostname                string $mach_def
d-i netcfg/get_domain                  string $CLOUD_DOMAIN
EOF
fi

# We will always use proxies no matter what (makes no sense not to)
cat >> $preseed_path <<-EOF

# Detected proxy live repo proxy so using apt-cache-ng
d-i mirror/country string manual
d-i mirror/http/hostname string $ACNG_HOST:$ACNG_PORT
d-i mirror/http/directory string /debian
d-i mirror/http/proxy string
d-i mirror/http/mirror select http://$ACNG_HOST:$ACNG_PORT

# Partition
d-i partman/confirm_write_new_label    boolean true
d-i partman/choose_partition           select Finish partitioning and write changes to disk
# d-i partman/choose_partition select finish
d-i partman/confirm                    boolean true
d-i partman/confirm_nooverwrite        boolean true

d-i partman-basicmethods/method_only   boolean false
d-i partman-partitioning/confirm_write_new_label boolean true

d-i partman-auto/disk                  string /dev/sda
d-i partman-auto/method                string lvm
d-i partman-auto-lvm/guided_size       string max
d-i partman-auto/purge_lvm_from_device boolean true
d-i partman-auto/confirm               boolean true
d-i partman-auto/choose_recipe         select Separate /home, /usr, /var, and /tmp partitions
# d-i partman-auto/choose_recipe         select atomic

d-i partman-lvm/device_remove_lvm      boolean true
d-i partman-lvm/confirm                boolean true
d-i partman-lvm/confirm_nooverwrite    boolean true

# Grub
d-i grub-installer/only_debian boolean true
d-i grub-installer/bootdev string default

# Finish
d-i finish-install/reboot_in_progress note

# Packages - TODO should cascade additively: (1) default packages, (2) env packages, (2) machine packages
d-i pkgsel/update-policy select none
d-i pkgsel/include string openssh-server python ntp curl net-tools dnsutils qemu-kvm libvirt0 bridge-utils

EOF

cat >> $preseed_path <<-EOF
# Setup for Post Installation Tasks: outside and inside the target
d-i preseed/late_command string \
wget http://$HTTP_HOST:$HTTP_PORT/$env_name/$mach_def/postinst; \
chmod +x ./postinst; \
in-target /postinst; \
rm -f ./postinst; \
cd /target; \
wget http://$HTTP_HOST:$HTTP_PORT/$env_name/$mach_def/postinst-in-target; \
in-target /postinst-in-target; \
rm -f ./postinst-in-target;
EOF

