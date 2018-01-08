# TODO List

## Major Problems

- Need to log to the webserer using request parameters (based 64 log text)
- [vagrant] ansible installation
- [vagrant] ansible integration with access log watcher for installers
- hook scripts for different states (keep in machine def): installing, post-install, rebooted
- ansible playbooks in machine definition directories for integration
- [tasksel] add config file processing for picking multiselect options
- [pkgsel] add file for adding additional packages
- switch to dhcp so we can have multiple machines being provisioned for each definition

- change name in installer greeter
- use graphical greeter on boot
- use different splash screens

- Add config logic **NOT** to touch existing raid or lvm partitions with existing data

- Make it pick up more specific file systems and use the environment filesystem
  as the fall back up to the environments file system configuration file.

## Minor Problems

- [minor] change sshd_config settings: no passwords, no root, only infra with keys
- [minor] splash screen for installer and installed system based on machine definition
- [minor] add bridge configuration parameter into settings for the VM (br0 will not work for everyone)
- [minor] test-iso.sh accidentally overwritting when trying to boot: warn before overwrite
- [minor] add kernel boot options to menu.cfg to prevent language and keymap questions
- [minor] add approx settings in VM for both debian and ubuntu
- [minor] documentation
- [minor] setup.sh in root of prj, tell if things missing, how to install
- [minor] support wifi in preseed, try acer laptop as experiment
- [minor] add logic to avoid windows partitions?

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

## Tested Configurations

- **compute-t0**: one large HDD gpt
- **compute-t1**: one small SSD dos (sys:data ratio not observed)
- **compute-t2**: one small SDD dos (boot), one large HDD

- **storage-t1**: one small SSD dos (boot), four large HDD RAID


## NOT yet tested but should be

- **storage-t2**: two small SDD dos (boot), four large HDD RAID
- **compute-t3**: t2 with device order reversed (should produce same results)
