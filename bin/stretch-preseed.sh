#!/bin/bash

# Simple Parameters
LOCALES='en_US en_US.UTF-8'
LANGUAGE='en'
COUNTRY='US'

# Associated with our scheme

## TODO do this from all sourced environment variables
if [ -z "$DEBUG" ]; then
    DEBUG='true'
fi

if [ -z "$ENVIRONMENT" ]; then
    ENVIRONMENT='mock'
fi

KEYS_HOST='172.16.1.20'
KEYS_PORT='80'
KEYS_FILE='authorized_keys'
AUTHORIZED_KEYS_URL='http://'$KEYS_HOST':'$KEYS_PORT'/'$ENVIRONMENT'/'$KEYS_FILE

ENABLE_NETCON="$DEBUG"

INFRA_FULLNAME="Infra Team"
INFRA_ACCOUNT="infra"
INFRA_ACCOUNT_PW=""

cat > ./preseed.cfg <<-EOF
# Net console
d-i debconf/priority                   select critical
d-i auto-install/enabled               boolean true

d-i anna/choose_modules string network-console
d-i preseed/early_command string anna-install network-console
d-i network-console/password-disabled boolean true
d-i network-console/authorized_keys_url string http://172.16.1.20/authorized_keys

# Account setup
d-i passwd/root-login boolean false
d-i passwd/user-fullname string Subutai User
d-i passwd/username string subutai
d-i passwd/user-password password ubuntai
d-i passwd/user-password-again password ubuntai
d-i user-setup/encrypt-home boolean false
d-i user-setup/allow-password-weak boolean true

# Locale setup
d-i debian-installer/locale string en_US
d-i debian-installer/country string US
d-i debian-installer/locale string en_US.UTF-8
d-i debian-installer/language string en

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
d-i clock-setup/ntp-server string 172.16.1.20

# Network Conifgurations
d-i netcfg/choose_interface select auto
d-i netcfg/disable_dhcp                boolean true
d-i netcfg/get_nameservers             string 172.16.1.1
d-i netcfg/get_ipaddress               string 172.16.1.212
d-i netcfg/get_netmask                 string 255.255.255.0
d-i netcfg/get_gateway                 string 172.16.1.1
d-i netcfg/confirm_static              boolean true
d-i netcfg/get_hostname                string mock-storage
d-i netcfg/get_domain                  string kg.cloud

# Detected proxy live repo proxy so using apt-cache-ng
d-i mirror/country string manual
d-i mirror/http/hostname string 172.16.1.20:3142
d-i mirror/http/directory string /debian
d-i mirror/http/proxy string
d-i mirror/http/mirror select http://172.16.1.20:3142

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

# Packages
d-i pkgsel/update-policy select none
d-i pkgsel/include string openssh-server ntp curl net-tools dnsutils qemu-kvm libvirt0 bridge-utils

# Setup for Post Installation Tasks: outside and inside the target
d-i preseed/late_command string \
wget http://172.16.1.20/postinst; \
chmod +x ./postinst; \
in-target /postinst; \
rm -f ./postinst; \
cd /target; \
wget http://172.16.1.20/postinst-in-target; \
in-target /postinst-in-target; \
rm -f ./postinst-in-target;
EOF