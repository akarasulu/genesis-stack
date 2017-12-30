vm_memory = 8192
vm_cpus   = 4

Vagrant.configure("2") do |config|
  config.vm.box = "debian/stretch64"
  config.vm.hostname = 'iso-builder'

  ["vmware_workstation", "vmware_fusion"].each do |vmware_provider|
    config.vm.provider(vmware_provider) do |vmware|
      vmware.whitelist_verified = true
      vmware.gui = true
      vmware.vmx["memsize"] = vm_memory
      vmware.vmx["numvcpus"] = vm_cpus
      vmware.vmx["vhv.enable"] = "TRUE"
      config.vm.synced_folder './', '/vagrant'
    end
  end

  config.vm.provider :virtualbox do |vb|
    vb.memory = vm_memory
    vb.cpus = vm_cpus
    config.vm.synced_folder './', '/vagrant'
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
    # config.vm.synced_folder './', '/vagrant', type: '9p', disabled: false, accessmode: "squash", owner: "1000"
  end

  config.vm.provision 'shell', 
    env: {
      "ACNG_HOST" => ENV['ACNG_HOST'],
      "ACNG_PORT" => ENV['ACNG_PORT'],
      "APPROX_HOST" => ENV['APPROX_HOST'],
      "APPROX_PORT" => ENV['APPROX_PORT']
      }, inline: <<-SHELL
    
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
    # apt-get -y install openssh-server ntp curl net-tools dnsutils nginx apt-cacher-ng approx
    
    # extras for virtualization (testing inside the box)
    # apt-get -y install qemu-kvm libvirt-daemon-system bridge-utils

    # prepare iso build environment
    apt-get build-dep -y debian-installer
    apt-get install -y fakeroot

    # apply patch to modify installer

    # This was for simple-cdd
    # cd /vagrant
    # if [ -f /vagrant/tmp/mirror/db/lockfile ]; then
    #   rm /vagrant/tmp/mirror/db/lockfile
    # fi 

    # Not using simple-cdd anymore
    # CMD='echo build-simple-cdd --debian-mirror '$APPROX_URL
    # sudo su -c '$1' vagrant -- $CMD
  SHELL

  # This will go away, a shell script will trigger these builds
  # for all the environment machine definitions. Configuration
  # files (preseed, pre, post installation files) will be generated
  # then the iso will be generated.
  config.vm.provision 'shell', 
    env: {
      "ACNG_HOST" => ENV['ACNG_HOST'],
      "ACNG_PORT" => ENV['ACNG_PORT'],
      "APPROX_HOST" => ENV['APPROX_HOST'],
      "APPROX_PORT" => ENV['APPROX_PORT']
      }, privileged: false, inline: <<-SHELL
    apt-get source -y debian-installer
    mv `find . -maxdepth 1 -type d -regex '^./debian-installer-2.*'` installer
    patch -R -p0 < /vagrant/installer.patch
    cd installer/build
    echo 'PRESEED=/vagrant/mock-storage-t1/preseed.cfg' > config/local
    echo 'USE_UDEBS_FROM=stretch' >> config/local
    fakeroot make rebuild_netboot
    
    if [ $? -eq 0 ]; then
      cp dest/netboot/mini.iso /vagrant/mock-storage-t1/installer.iso
    fi
  SHELL
end