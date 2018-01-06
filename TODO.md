# TODO List

## Critical Problems

### General

## Major Problems

- need to test other raid configurations to see they work too
- need to log to the webserer using request parameters (based 64 log text)
- switch to dhcp so we can have multiple machines being provisioned for each definition
- add config logic **NOT** to touch existing raid or lvm partitions with existing data
- [vagrant] ansible installation
- [vagrant] ansible integration with access log watcher for installers
- hook scripts for different states (keep in machine def): installing, post-install, rebooted
- ansible playbooks in machine definition directories for integration
- [tasksel] add config file processing for picking multiselect options
- [pkgsel] add file for adding additional packages


## Minor Problems

- [minor] change sshd_config settings: no passwords, no root, only infra with keys
- [minor] splash screen for installer and installed system based on machine definition
- [minor] add bridge configuration parameter into settings for the VM (br0 will not work for everyone)
- [minor] when outside of vagrant ancestor path build-iso.sh fails
- [minor] test-iso.sh accidentally overwritting when trying to boot: warn before overwrite
- [minor] add kernel boot options to menu.cfg to prevent language and keymap questions
- [minor] add approx settings in VM for both debian and ubuntu
- [minor] add subutai splash
- [minor] documentation
- [minor] setup.sh in root of prj, tell if things missing, how to install

- [minor] support wifi in preseed, try acer laptop as experiment
- [minor] add logic to avoid windows partitions?

Overrides for local build and test settings in debug mode. These overrides
should only be used when in debug mode or when explicitly requested by yml
fields with the '$override', '$local', or '$vm' text.

If name instead of IP then check DNS for name resolution.

- .genesis-stack/settings.yml
- .genesis-stack/environments/...

Generate the environment and hosts file.

- Services Setup on Vagrant VM
  - approx
  - Ansible
- SSH Configuration
- Start using some logging library
- Add Approx and Cacher NG use from VM (if not present in environment)
- packer builds of virtual machines
