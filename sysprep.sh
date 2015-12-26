#!/bin/bash
# .----------------------------------------------------------------------------.
# |                              sysprep.sh                                    |
# |                              ----------                                    |
# |                                                                            |
# |                   lazy simple server setup script                          |
# |                                                                            |
# |                 designed for Digital Ocean droplets                        |
# |                      (but reasonably portable)                             |
# |                                                                            |
# |               https://github.com/BigglesZX/sysprep.sh                      |
# `----------------------------------------------------------------------------'

# we need to be root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root." 1>&2
   exit 1
fi

# prompt
echo "\[\033[38;5;10m\]sysprep.sh\[$(tput sgr0)\]"
echo "This script will perform initial setup actions on this server."
read -r -p "Type 'Y' to continue or anything else to abort: " GO
if [ "$GO" != "Y" ]; then
    echo "Aborting." 1>&2
    exit 1
fi

# set timezone
echo "Setting timezone..."
dpkg-reconfigure tzdata

# set root password
echo "Setting root password..."
passwd

# ask for new standard user's username
read -r -p "Please enter username for new standard user: " USERNAME
if [ -z "$USERNAME" ]; then
    echo "No username entered, aborting."
    exit 1
fi

# add regular user
echo "Creating standard user..."
useradd -s /bin/bash -d /home/$USERNAME -m -U $USERNAME
passwd $USERNAME

# copy SSH authorized_keys
echo "Copying SSH public key to $USERNAME's home directory..."
mkdir /home/$USERNAME/.ssh
chown $USERNAME.$USERNAME /home/$USERNAME/.ssh/
cp /root/.ssh/authorized_keys /home/$USERNAME/.ssh/authorized_keys
chown $USERNAME.$USERNAME /home/$USERNAME/.ssh/authorized_keys

# set sensible prompt
echo "Setting up bash prompt..."
echo "PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[00m\]\\$ '" >> /home/$USERNAME/.bashrc

# add $USERNAME to sudoers
echo "Adding $USERNAME to sudoers with ALL privileges..."
echo "$USERNAME ALL=(ALL:ALL) ALL" > /etc/sudoers.d/sysprep
chmod 0440 /etc/sudoers.d/sysprep

# python setup
echo "Setting up python..."
apt-get update
apt-get install python-setuptools
easy_install pip
pip install ipdb ipython virtualenv virtualenvwrapper

# virtualenv .bashrc stuff
echo "Completing virtualenv config for $USERNAME..."
echo "WORKON_HOME=\$HOME/.virtualenvs" >> /home/$USERNAME/.bashrc
echo "export PROJECT_HOME=\$HOME/sites" >> /home/$USERNAME/.bashrc
echo "#export VIRTUALENV_DISTRIBUTE=true" >> /home/$USERNAME/.bashrc
echo "source /usr/local/bin/virtualenvwrapper.sh" >> /home/$USERNAME/.bashrc

# swapfile setup
echo "Adding swapfile..."
dd if=/dev/zero of=/swapfile bs=1024 count=512k
mkswap /swapfile
swapon /swapfile
echo "/swapfile none swap sw 0 0" >> /etc/fstab
echo 10 | tee /proc/sys/vm/swappiness
echo vm.swappiness = 10 | tee -a /etc/sysctl.conf
chown root:root /swapfile
chmod 0600 /swapfile

# iptables setup
echo "Setting up iptables with standard web server config..."
apt-get install iptables-persistent
service iptables-persistent start
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -P INPUT DROP
iptables -I INPUT 1 -i lo -j ACCEPT
iptables-save > /etc/iptables/rules.v4

# install other common packages
echo "Installing other common apt packages..."
apt-get install git ntp python-dev nginx mysql-server mysql-client libmysqlclient-dev memcached python-memcache

# mysql timezone loading
echo "Loading timezone data into mysql..."
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root mysql
service mysql restart

# install Pillow dependencies
echo "Installing Pillow dependencies..."
apt-get install libjpeg-dev libjpeg8-dev libpng3 libfreetype6-dev
ln -s /usr/lib/`uname -i`-linux-gnu/libfreetype.so /usr/lib
ln -s /usr/lib/`uname -i`-linux-gnu/libjpeg.so /usr/lib
ln -s /usr/lib/`uname -i`-linux-gnu/libz.so /usr/lib
ln -s /usr/include/freetype2 /usr/local/include/freetype

# cleanup
echo "Cleaning up..."
apt-get clean

# done
echo "Done!"
