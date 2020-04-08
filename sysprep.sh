#!/bin/bash
# .----------------------------------------------------------------------------.
# |                              sysprep.sh                                    |
# |                              ----------                                    |
# |                                                                            |
# |                   lazy simple server setup script                          |
# |                                                                            |
# |               designed for 512MB Digital Ocean droplets                    |
# |                      (but reasonably portable)                             |
# |                                                                            |
# |               https://github.com/BigglesZX/sysprep.sh                      |
# `----------------------------------------------------------------------------'

sleep 1
NC='\033[0m'
GR='\033[0;32m'
echo -e "${GR}sysprep.sh${NC}"

# we need to be root
if [ "$(id -u)" != "0" ]; then
   echo "Sorry! This script must be run as root." 1>&2
   exit 1
fi

# prompt
echo "This script will perform initial setup actions on this server."
echo ""
echo "Please read the README and inspect the contents of the script for more "
echo "information about the specific actions running this script will perform."
echo "You should always be able to find the latest version of this script at:"
echo -e "${GR}https://github.com/BigglesZX/sysprep.sh${NC}"
echo ""
read -r -p "Type 'Y' to continue or anything else to abort: " GO
if [ "$GO" != "Y" ]; then
    echo "Aborting." 1>&2
    exit 1
fi

# set timezone
echo -e "${GR} * Updating apt and setting timezone...${NC}"
apt-get update
apt-get -y dist-upgrade
apt-get -y autoremove
dpkg-reconfigure tzdata

# set root password
echo -e "${GR} * Setting root password...${NC}"
passwd

# ask for new standard user's username
read -r -p "Please enter username for new standard user: " USERNAME
if [ -z "$USERNAME" ]; then
    echo "No username entered, skipping user creation, SSH key copy, sudo and virtualenv setup." 1>&2
fi

# add regular user
if [ ! -z "$USERNAME" ]; then
    echo -e "${GR} * Creating standard user...${NC}"
    useradd -s /bin/bash -d /home/$USERNAME -m -U $USERNAME
    passwd $USERNAME
fi

# copy SSH authorized_keys
if [ ! -z "$USERNAME" ]; then
    echo -e "${GR} * Copying SSH public key to ${USERNAME}'s home directory...${NC}"
    mkdir /home/$USERNAME/.ssh
    chown $USERNAME.$USERNAME /home/$USERNAME/.ssh/
    cp /root/.ssh/authorized_keys /home/$USERNAME/.ssh/authorized_keys
    chown $USERNAME.$USERNAME /home/$USERNAME/.ssh/authorized_keys
fi

# set sensible prompt
if [ ! -z "$USERNAME" ]; then
    echo -e "${GR} * Setting up bash prompt...${NC}"
    echo "PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[00m\]\\$ '" >> /home/$USERNAME/.bashrc
fi

# add $USERNAME to sudoers
if [ ! -z "$USERNAME" ]; then
    echo -e "${GR} * Adding ${USERNAME} to sudoers with ALL privileges...${NC}"
    echo "${USERNAME} ALL=(ALL:ALL) ALL" > /etc/sudoers.d/sysprep
    chmod 0440 /etc/sudoers.d/sysprep
fi

# python setup
echo -e "${GR} * Setting up python..."
apt-get -y install python-setuptools python3-setuptools python-pip python3-pip
pip install ipdb ipython virtualenv virtualenvwrapper

# virtualenv .bashrc stuff
if [ ! -z "$USERNAME" ]; then
    echo -e "${GR} * Completing virtualenv config for ${USERNAME}..."
    echo "WORKON_HOME=\$HOME/.virtualenvs" >> /home/$USERNAME/.bashrc
    echo "export PROJECT_HOME=\$HOME/sites" >> /home/$USERNAME/.bashrc
    echo "source /usr/local/bin/virtualenvwrapper.sh" >> /home/$USERNAME/.bashrc
fi

# swapfile setup
echo -e "${GR} * Adding swapfile...${NC}"
dd if=/dev/zero of=/swapfile bs=1024 count=1024k
chown root:root /swapfile
chmod 0600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile none swap sw 0 0" >> /etc/fstab
echo 10 | tee /proc/sys/vm/swappiness
echo vm.swappiness = 10 | tee -a /etc/sysctl.conf

# iptables setup
echo -e "${GR} * Setting up iptables with standard web server config...${NC}"
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -P INPUT DROP
iptables -I INPUT 1 -i lo -j ACCEPT
apt-get -y install iptables-persistent
iptables-save > /etc/iptables/rules.v4

# install other common packages
echo -e "${GR} * Installing other common apt packages...${NC}"
add-apt-repository -y universe
add-apt-repository -y ppa:certbot/certbot
apt-get update
apt-get -y install git ntp gettext python-dev python3-dev nginx mysql-server mysql-client libssl-dev default-libmysqlclient-dev memcached python-memcache htop libffi-dev libxml2-dev libxslt1-dev python-lxml fail2ban certbot python-certbot-nginx haveged rng-tools5

# ensure haveged is set to start at boot
update-rc.d haveged defaults

# generate Diffie-Hellman profile
mkdir -p /etc/ssl/nginx
openssl dhparam -out /etc/ssl/nginx/dhparam.pem 2048

# set up apt unattended upgrades
dpkg-reconfigure --priority=low unattended-upgrades

# mysql timezone loading
echo -e "${GR} * Loading timezone data into MySQL...${NC}"
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root mysql
service mysql restart

# mysql root user config
echo -e "${GR} * Configuring MySQL root user...${NC}"
read -s -p "Enter new MySQL root password: " MYSQLPASSWORD
echo ""
mysql -u root -e "USE mysql; UPDATE user SET authentication_string=PASSWORD('$MYSQLPASSWORD') WHERE User='root'; UPDATE user SET plugin=\"mysql_native_password\"; FLUSH PRIVILEGES;"

# install Pillow dependencies
echo -e "${GR} * Installing Pillow dependencies...${NC}"
apt-get -y install libtiff5-dev libjpeg8-dev libopenjp2-7-dev zlib1g-dev libfreetype6-dev libwebp-dev

# cleanup
echo -e "${GR} * Cleaning up...${NC}"
apt-get -y autoremove
apt-get clean

# warn about ssh root login
echo ""
echo " *** You may wish to remove root's ability to log in via SSH    ***"
echo " *** To do so, add 'PermitRootLogin no' to /etc/ssh/sshd_config ***"
echo " *** Then restart ssh: # service ssh restart                    ***"
echo ""

# done
echo -e "${GR}Done! Please reboot soon. Enjoy!${NC}"
