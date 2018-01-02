# TODO List

## Critical Problems

- add partitioning code (blocker: usb image boot)

## Major Problems

- [test-iso.sh] with boot option does not have connectivity
- [stretch-preseed.sh] infra password is not getting set in preseed
- [test-iso.sh] produce usb image from iso and test boot with it
- [vagrant] ansible installation
- [vagrant] add systemd process to watch logs for installers

## Minor Problems

- [minor] when outside of vagrant ancestor path build-iso.sh fails
- [minor] test-iso.sh accidentally overwritting when trying to boot: warn before overwrite
- [minor] add kernel boot options to menu.cfg to prevent language and keymap questions
- [minor] add approx settings in VM for both debian and ubuntu
- [minor] documentation
- [minor] setup.sh in root of prj, tell if things missing, how to install

- setup mock tests for build
  - try acer laptop as experiment
- add logic to avoid windows partitions?
- add config logic not to touch existing raid or lvm partitions with data

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
