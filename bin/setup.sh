#!/bin/bash

BASE_DIR="`dirname \"$0\"`"
BASE_DIR="`( cd \"$BASE_DIR\" && pwd )`"
TOP_DIR="$BASE_DIR/.."

if [ -z "$TOP_DIR" ]; then
  TOP_DIR="$BASE_DIR"
fi

. $TOP_DIR/lib/general
. $TOP_DIR/lib/yaml
. $TOP_DIR/lib/settings
. $TOP_DIR/lib/vm

if [ -z "$(echo $PATH | grep 'genesis-stack/bin')" ]; then
  echo "Adding base genesis-stack to path."
  echo "Stop this message in new terminals. Put this into your profile:"
  echo "export PATH=$PATH:$TOP_DIR/bin"
  export PATH=$TOP_DIR/bin
fi

if [ ! -f "$overrides" ]; then
  echo "No overrides directy setup: $overrides"
  echo "This might present problems in development mode with the virtual machine."
fi

if [ "$environments" == "$TOP_DIR/environments" ]; then
  echo "Using embedded ./environments directory containing mock environments."
fi

if [ ! -d "$environments" ]; then
  echo "Environments directory does not exist: $environments"
  echo "This will certainly cause problems."
  echo "Check in $overrides/settings.yml to make sure it points to the correct path."
fi
# TODO: check for vagrant
vagr_fun(){
  local var1=`vagrant --version`
  echo "You must have vagrant version 2.0 or higher "
  if [ $? -eq 1 ]; then
    echo " 'vagrant' is currently not installed "
    echo -n "Enter 'Y/n' if you wont to install vagrant :  "
    read vagr_var
      if [ "$vagr_var" == "Y" ];then
        wget https://releases.hashicorp.com/vagrant/2.0.1/vagrant_2.0.1_x86_64.deb	
        sudo dpkg -i vagrant_2.0.1_x86_64.deb
        echo "$var1"| tail -n1
      fi 
  else 
    echo "$var1"| tail -n1
  fi
  }
vagr_fun
echo ""

# TODO: check for libvirt
libvir_fun(){
local lib_var=`virsh --version`
  if [ $? -eq 1 ]; then
    echo " 'virsh' is currently not installed "
    echo -n "Enter 'Y/n' if you wont to install libvert-bin : "
    read lib_var2
    if [ "$lib_var2" == "Y" ];then
      sudo apt install qemu-kvm libvirt-bin 
      sudo apt-get -f install 
     #sudo adduser $USER libvirtd
      echo "Libvirt version: $lib_var"| tail -n1
    fi
  else             
    echo "Libvirt version: $lib_var"| tail -n1
  fi
  }
libvir_fun
echo ""
# TODO: check for vagrant-libvirt
vagrant_libvirt(){
  echo "plugin list :"
  sudo vagrant plugin list
  echo ""
  echo -n "Enter 'Y/n' if you want to install vagrant-libvirt : "
  read vag_lib
  if [ "$vag_lib" == "Y" ];then
    wget http://production.cf.rubygems.org/rubygems/rubygems-update-2.0.3.gem
    sudo gem install rubygems-update-2.0.3.gem 
    sudo update_rubygems
    sudo apt-get build-dep vagrant ruby-libvirt
    sudo apt-get install -y qemu libvirt-bin ebtables dnsmasq 
    sudo apt-get install -y libxslt-dev libxml2-dev libvirt-dev zlib1g-dev ruby-dev 
    wget https://api.rubygems.org/gems/fog-xml-0.1.3.gem
    sudo vagrant plugin install vagrant-libvirt
  fi
  }
vagrant_libvirt
echo ""

# TODO: check for proper networking setup
ping_net(){
  ping -c1 -w7 8.8.8.8 &>/dev/null
  if [ $? -eq 1 ]; then
    echo "Ping failed"
  else 
    echo "Ping successful"
  fi
  }
ping_net
echo ""
# TODO: check for bridge device on local machine
bridge(){
  echo "bridge device on local machine : "
  brctl show ##| awk 'FNR == 2 {print $1}'
  }
bridge

echo "Cleaning up past runs ..."
echo "    => " $(cleanup.sh)
echo "Firing up virtual machine ..."
echo "    => "
vm_run
