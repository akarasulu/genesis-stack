# TODO List

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