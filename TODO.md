# TODO List

## Critical Problems

### Local Variance and Precalculated Operations

Local variance is a big problem. Precalculating the changes in advance will
**NOT** work wth bus and minor device configurations. We have to have some
intelligent code running inside the Debian Installer to make this work. Let's
step back and do this right:

1. ~~Enable postinst script to pull down the genesis-stack code with scripts
   and libs to run inside the Debian Installer on bash.~~
2. Write scripts to normalize and assess the real with the ideal configuration.
   It may abort or continue to partition after normalizing the configuration.
   - Generate the effective.drives.yml file
   - Compare the two and decide
   - Decide if the effective strategy applies and abort if not
3. We can precompute a few things to simplify the scripts that run in the DI
   environment:
   - we know the specific strategy for the machine
   - we know whether or not it will have zero, one or two raidsets

Generate the effective.drives.yml. Then compare:

0. Filter out usb and cdrom drives: scsi and ata
1. Does the total # of drives match?
2. Do the drive sizes match within 1% stddev?
3. Do we have the same number of drives in each exected raidset?
4. Grab the new drive deviceIds and partition with them.

### General

- add partitioning code
- add config logic **NOT** to touch existing raid or lvm partitions with existing data
- need to log to the webserer using request parameters (based 64 log text)
- need to define a set of request parameters to post with each request

## Major Problems

- [stretch-preseed.sh] infra password is **NOT** getting set in preseed
- need to put effective keys into infra user's account: ~infra/.ssh/authorized_keys
- change sshd_config settings: no passwords, no root, only infra with keys
- switch to dhcp so we can have multiple machines being provisioned for each definition
- [vagrant] ansible installation
- [vagrant] ansible integration with access log watcher for installers
- hook scripts for different states (keep in machine def): installing, post-install, rebooted
- ansible playbooks in machine definition directories for integration

## Minor Problems

- [minor] add bridge configuration parameter into settings for the VM (br0 will not work for everyone)
- [minor] when outside of vagrant ancestor path build-iso.sh fails
- [minor] test-iso.sh accidentally overwritting when trying to boot: warn before overwrite
- [minor] add kernel boot options to menu.cfg to prevent language and keymap questions
- [minor] add approx settings in VM for both debian and ubuntu
- [minor] add subutai splash
- [minor] documentation
- [minor] setup.sh in root of prj, tell if things missing, how to install
- [tasksel] add config file processing for picking multiselect options
- [pkgsel] add file for adding additional packages

- setup mock tests for build
  - try acer laptop as experiment

- add logic to avoid windows partitions?

sudo apt-get install libguestfs-tools

Overrides for local build and test settings in debug mode. These overrides
should only be used when in debug mode or when explicitly requested by yml
fields with the '$override', '$local', or '$vm' text.

If name instead of IP then check DNS for name resolution.

- .genesis-stack/settings.yml
- .genesis-stack/environments/...

Generate the environment and hosts file.

- Overrides for debug mode (local env vs. production env usage)
  - Network settings
  - Hosts?
  - Use DNS detection?
- Services Setup on Vagrant VM
  - acng
  - approx
  - NGINX:
    - keys
    - Write postinst script to pull from NGINX
    - Make VM serve environments directory w/ NGINX
    - configure access logs
    - access log scanning systemd command
  - Ansible
- SSH Configuration
- Start using some logging library
- Add Approx and Cacher NG use from VM (if not present in environment)
- Add Ansible to VM and script services to trigger it from NGINX logs
- packer builds of virtual machines
