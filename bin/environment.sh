#!/bin/bash

# Usage: environment.sh <env_name>
# Generates files for the environment from the yaml file if they do not exist:
#  - the environment file
#  - the hosts file
#  - the ssh_config file
#  - the authorized_keys file
#
# If the files already exist, they are intelligently merged. If debug mode is
# enabled then values are merged in from environment defaults.

# ARG $1: the name of the environment


# Some rules:
#   - Set passwords in shell before your build: avoids storing it here!

BUILD_MACHINES="mock-compute-t1 \
    mock-storage-t1"

#
# User settings
#

# Administrative account for infrastructure staff
INFRA_FULLNAME="Infrastructure Team"
INFRA_ACCOUNT="infra"
INFRA_PASSWORD=$INFRA_PASSWORD

# User account with NVMS libvirt access
NONINFRA_FULLNAME="Subutai Ambassadors"
NONINFRA_ACCOUNT="ambassador"
NONINFRA_PASSWORD=$NONINFRA_PASSWORD

# Ternary: true, false, nopasswd
INFRA_SUDOERS="nopasswd"
NONINFRA_SUDOERS="false"

#
# Domain and Network Settings
#

# TODO: Free DDNS and revproxy service for ambassadors
# TODO: Use Subutai infrastructure for this and more including containers
EXTERNAL_DOMAIN='kg.optdyn.com'
EXTERNAL_DNS='212.112.96.1 212.112.96.7'

CLOUD_DOMAIN='kg.cloud'
CLOUD_NETWORK='172.16.0.0'
CLOUD_NETMASK='255.255.0.0'
CLOUD_GATEWAY='172.16.0.1'
CLOUD_DNS='172.16.1.1'

# Extra network for disk traffic for Ceph
DISK_NETWORK='192.168.1.0'
DISK_NETMASK='255.255.255.0'

# Physical are machines "PREPared" (installed) then run on these networks
PHYSMACH_NET='172.16.1.0'
PHYSPREP_NET='172.16.2.0'

# Virtual machines (for infra) are "PREPared" then run on these networks
VIRTMACH_NET='172.16.3.0'
VIRTPREP_NET='172.16.4.0'

CEPH_AVAILABLE='no'

#
# Ansiliary Infrastructure
#

# Debian Approx Proxy Server (approx)
APPROX_HOST='approx'
APPROX_PORT='9999'

# Next Generation Apt Cacher Proxy Server (apt-cacher-ng)
ACNG_HOST='acng'
ACNG_PORT='3142'

# HTTP Server
HTTP_HOST='www'
HTTP_PORT='80'

NTP_HOST='ntp'

# CDN hosts prefixed to this for sysnet, dev, and master
CDN_HOST_BASE='cdn'

# Builds ISO installer and virtual disk images
IMAGE_BUILDER_HOST='images'

# Ansible Server
ANSIBLE_HOST='ansible'

# SSH Jump Host
JUMP_HOST='jump'

# Jenkins Server Host
JENKINS_HOST='jenkins'

# Place to put and get infrastructure team keys
KEYS_HOST='keys'
KEYS_PORT='80'
KEYS_PATH='/authorized_keys'
