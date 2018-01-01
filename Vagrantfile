vm_memory = 8192
vm_cpus   = 4

# Need to figure out how to handle ACNG/APPROX
# We provide to this host, yet expect it to server
# As a caching proxy server too?
acng_port = 13143
approx_port = 10001
configs_port = 11888

# Read settings yaml, extract the environments directory, and
# mount to /environments as vagrant user which nginx runs as
ENVS_PATH='/environments'
DEFAULT_ROOT='/var/www/html'
env_dir = "#{Dir.pwd}" + ENVS_PATH     # default to environments inside
settings = File.expand_path('~/.genesis-stack/settings.yml')
if File.exist?(settings)
  temp = YAML.load_file(settings)
  unless temp['environments'].nil? 
    env_dir = File.expand_path(temp['environments'])
  end
end

Vagrant.configure("2") do |config|
  config.vm.box = "debian/stretch64"
  config.vm.hostname = 'iso-builder'

  config.vm.network "forwarded_port", guest: 80, host: configs_port
  config.vm.network "forwarded_port", guest: 3142, host: acng_port
  config.vm.network "forwarded_port", guest: 9999, host: approx_port

  ["vmware_workstation", "vmware_fusion"].each do |vmware_provider|
    config.vm.provider(vmware_provider) do |vmware|
      vmware.whitelist_verified = true
      vmware.gui = true
      vmware.vmx["memsize"] = vm_memory
      vmware.vmx["numvcpus"] = vm_cpus
      vmware.vmx["vhv.enable"] = "TRUE"
      config.vm.synced_folder './', '/vagrant'
      config.vm.synced_folder env_dir, DEFAULT_ROOT + ENVS_PATH
    end
  end

  config.vm.provider :virtualbox do |vb|
    vb.memory = vm_memory
    vb.cpus = vm_cpus
    config.vm.synced_folder './', '/vagrant'
    config.vm.synced_folder env_dir, DEFAULT_ROOT + ENVS_PATH
  end

  config.vm.provider :libvirt do |libvirt|
    # libvirt.random_hostname = true
    # this should be kvm for 5x more performance but having problems
    # libvirt.driver = 'qemu'

    # add more juice otherwise we only get 1 cpu and 512m
    libvirt.cpus = vm_cpus
    libvirt.memory = vm_memory
    libvirt.nested = 'true'
    libvirt.random_hostname = 'iso-builder'
    config.vm.synced_folder './', '/vagrant', type: 'nfs', nfs_udp: false, nfs_version: 4
    config.vm.synced_folder env_dir, DEFAULT_ROOT + ENVS_PATH, type: 'nfs', nfs_udp: false, nfs_version: 4
    # config.vm.synced_folder './', '/vagrant', type: '9p', disabled: false, accessmode: "squash", owner: "1000"
  end

  config.vm.provision 'shell', 
    env: {
      "ACNG_HOST" => ENV['ACNG_HOST'],
      "ACNG_PORT" => ENV['ACNG_PORT'],
      "APPROX_HOST" => ENV['APPROX_HOST'],
      "APPROX_PORT" => ENV['APPROX_PORT']
      }, inline: <<-SHELL
    
    ## Need to make this conditional
    ACNG_URL="http://$ACNG_HOST:$ACNG_PORT"
    APPROX_URL="http://$APPROX_HOST:$APPROX_PORT/debian/"

    # Apt settings
    echo 'Using '$ACNG_URL' and '$APPROX_URL' for deb pkg caching'
    echo 'Acquire::http::Proxy "'$ACNG_URL'";' > /etc/apt/apt.conf.d/02proxy

    echo "Finding nearest apt mirror even when caching (not everything gets cached)"
    apt-get -y update
    apt-get install -y netselect-apt
    country=`curl -s ipinfo.io | grep country | awk -F ':' '{print $2}' | sed -e 's/[", ]//g'`
    if [ "KG" = "$country" ]; then
      country='KZ'
    fi

    netselect-apt -c $country &> /dev/null
    if [ ! "$?" = "0" ]; then
      netselect-apt -c US &> /dev/null
    fi

    if [ -f "sources.list" ]; then
      rm /etc/apt/sources.list
      
      while read line; do
        if [ -n "$(echo $line | egrep '^#.*')" -o -z "$(echo $line | grep '^deb .*')" ]; then
          continue;
        fi

        echo "$line non-free" >> /etc/apt/sources.list;
        echo "$line non-free" | sed -e 's/deb /deb-src /' >> /etc/apt/sources.list;
      done < sources.list
    fi

    apt-get -y update

cat > /etc/environment <<-EOF
LANG=en_US.UTF-8
LANGUAGE=en_US.UTF-8
LC_CTYPE="C"
LC_NUMERIC="C"
LC_TIME="C"
LC_COLLATE="C"
LC_MONETARY=en_US.UTF-8
LC_MESSAGES="C"
LC_PAPER=en_US.UTF-8
LC_NAME=en_US.UTF-8
LC_ADDRESS=en_US.UTF-8
LC_TELEPHONE=en_US.UTF-8
LC_MEASUREMENT=en_US.UTF-8
LC_IDENTIFICATION=en_US.UTF-8
LC_ALL=
EOF

    . /etc/environment
    cat /etc/locale.gen | sed 's/^# en_US.UTF-8/en_US.UTF-8/g' > /etc/locale.gen.new
    rm /etc/locale.gen
    mv /etc/locale.gen.new /etc/locale.gen
    locale-gen en_US.UTF-8
    dpkg-reconfigure -f noninteractive locales

    # building packages (might remove)
    # apt-get -y install debhelper devscripts

    # basics
    apt-get -y install openssh-server ntp curl net-tools dnsutils nginx apt-cacher-ng approx ntp ntpdate

    # extras for virtualization (testing inside the box)
    # apt-get -y install qemu-kvm libvirt-daemon-system bridge-utils

    # prepare iso build environment
    apt-get build-dep -y debian-installer
    apt-get install -y fakeroot
  SHELL

  config.vm.provision 'file', source: '.bashrc', destination: '.bashrc'
  config.vm.provision 'file', source: '.bash_logout', destination: '.bash_logout'
  config.vm.provision 'file', source: '.profile', destination: '.profile'

  config.vm.provision 'shell', privileged: false, inline: <<-SHELL
    # Setup the debian installer sources
    apt-get source -y debian-installer
    mv `find . -maxdepth 1 -type d -regex '^./debian-installer-2.*'` installer
    patch -R -p0 < /vagrant/installer.patch
  SHELL
end
