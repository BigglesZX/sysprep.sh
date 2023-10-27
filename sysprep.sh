#!/bin/bash
# .----------------------------------------------------------------------------.
# |                              sysprep.sh                                    |
# |                              ==========                                    |
# |                                                                            |
# |                   lazy simple server setup script                          |
# |                                                                            |
# |               designed for 1GB DigitalOcean droplets                       |
# |                      (but reasonably portable)                             |
# |                                                                            |
# |               https://github.com/BigglesZX/sysprep.sh                      |
# `----------------------------------------------------------------------------'

NC='\033[0m'
GR='\033[0;32m'
BLD='\e[1m'
UND='\e[4m'
NOR='\e[0m'
clear
echo -e "${GR}${UND}sysprep.sh${NC}${NORM}"

# we need to be root
if [ "$(id -u)" != "0" ]; then
   echo "Sorry! This script must be run as root." 1>&2
   exit 1
fi

# prompt
echo -e "\n${BLD}This script will perform initial setup actions on this server.${NOR} Some of these actions are destructive, so avoid running this script on previously-configured servers. \n\nPlease read the ${BLD}README${NOR} and inspect the contents of the script for more information about the specific actions this script will perform. You should always be able to find the latest version of this script at: \n\n${GR}https://github.com/BigglesZX/sysprep.sh${NC}\n\n" | fold -s
read -r -p "Type 'Y' to continue or anything else to abort: " GO
if [ "$GO" != "Y" ]; then
    echo "Aborting." 1>&2
    exit 1
fi

# update apt
echo -e "${GR} * Updating apt…${NC}"
apt-get update
apt-get -y dist-upgrade
apt-get -y autoremove

# set timezone
echo -e "${GR} * Setting timezone…${NC}"
dpkg-reconfigure tzdata

# set root password
echo -e "${GR} * Setting root password…${NC}"
passwd

# ask for new standard user's username
read -r -p "Please enter username for new standard user, or leave blank to skip: " USERNAME
if [ -z "$USERNAME" ]; then
    echo "No username entered, skipping user creation, SSH key copy, sudo and virtualenv setup." 1>&2
fi

# add regular user
if [ ! -z "$USERNAME" ]; then
    echo -e "${GR} * Creating standard user…${NC}"
    useradd -s /bin/bash -d /home/$USERNAME -m -U $USERNAME
    passwd $USERNAME
fi

# copy SSH authorized_keys
if [ ! -z "$USERNAME" ]; then
    echo -e "${GR} * Copying SSH public key to ${USERNAME}'s home directory…${NC}"
    mkdir /home/$USERNAME/.ssh
    chown $USERNAME.$USERNAME /home/$USERNAME/.ssh/
    cp /root/.ssh/authorized_keys /home/$USERNAME/.ssh/authorized_keys
    chown $USERNAME.$USERNAME /home/$USERNAME/.ssh/authorized_keys
fi

# enable colour bash prompt
if [ ! -z "$USERNAME" ]; then
    echo -e "${GR} * Setting up bash prompt…${NC}"
    sed -i -e 's/#force_color_prompt=yes/force_color_prompt=yes/g' /home/$USERNAME/.bashrc
fi

# add $USERNAME to sudoers
if [ ! -z "$USERNAME" ]; then
    echo -e "${GR} * Adding ${USERNAME} to sudoers with ALL privileges…${NC}"
    echo "${USERNAME} ALL=(ALL:ALL) ALL" > /etc/sudoers.d/sysprep
    chmod 0440 /etc/sudoers.d/sysprep
fi

# python setup
echo -e "${GR} * Setting up python…${NC}"
apt-get -y install python-setuptools python3-setuptools python3-pip pipenv
pip install ipdb ipython virtualenv virtualenvwrapper

# virtualenv .bashrc stuff
if [ ! -z "$USERNAME" ]; then
    echo -e "${GR} * Completing virtualenv config for ${USERNAME}…${NC}"
    echo "" >> /home/$USERNAME/.bashrc
    echo "export WORKON_HOME=\$HOME/.virtualenvs" >> /home/$USERNAME/.bashrc
    echo "export PROJECT_HOME=\$HOME/sites" >> /home/$USERNAME/.bashrc
    echo "export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3" >> /home/$USERNAME/.bashrc
    echo "export PIPENV_VENV_IN_PROJECT=1" >> /home/$USERNAME/.bashrc
    echo "source /usr/local/bin/virtualenvwrapper.sh" >> /home/$USERNAME/.bashrc
fi

# swapfile setup
echo -e "${GR} * Adding swapfile…${NC}"
dd if=/dev/zero of=/swapfile bs=1024 count=1024k
chown root:root /swapfile
chmod 0600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile none swap sw 0 0" >> /etc/fstab
echo 10 | tee /proc/sys/vm/swappiness
echo vm.swappiness = 10 | tee -a /etc/sysctl.conf

# iptables setup
echo -e "${GR} * Setting up iptables with standard web server config…${NC}"
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -P INPUT DROP
iptables -I INPUT 1 -i lo -j ACCEPT
apt-get -y install iptables-persistent
netfilter-persistent save

# install other common packages
echo -e "${GR} * Installing other common apt packages…${NC}"
add-apt-repository -y universe
apt-get update
apt-get -y install mlocate git systemd-timesyncd gettext python-dev-is-python3 python3-dev nginx mysql-server mysql-client libssl-dev default-libmysqlclient-dev memcached python3-memcache htop libffi-dev libxml2-dev libxslt1-dev python3-lxml fail2ban python3-certbot-nginx haveged rng-tools5 libmagic1

# add nginx restart hook to certbot config
echo "" >> /etc/letsencrypt/cli.ini
echo "deploy-hook = systemctl reload nginx" >> /etc/letsencrypt/cli.ini

# ensure haveged is set to start at boot
update-rc.d haveged defaults

# generate Diffie-Hellman profile
mkdir -p /etc/ssl/nginx
openssl dhparam -out /etc/ssl/nginx/dhparam.pem 2048

# generate self-signed SSL certificate so that HTTPS can be enabled for nginx default site
echo -e "${GR} * Generating self-signed SSL certificate…${NC}"
echo "*** When prompted for the 'Common Name' field, enter the server's IP address ***"
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt

# update nginx defaultsite config
echo -e "${GR} * Updating nginx default site config…${NC}"
curl https://raw.githubusercontent.com/BigglesZX/sysprep.sh/main/snippets/self-signed.conf -o /etc/nginx/snippets/self-signed.conf
curl https://raw.githubusercontent.com/BigglesZX/sysprep.sh/main/snippets/ssl-params.conf -o /etc/nginx/snippets/ssl-params.conf
curl https://raw.githubusercontent.com/BigglesZX/sysprep.sh/main/snippets/defaultsite.conf -o /etc/nginx/sites-available/default

# set up apt unattended upgrades
dpkg-reconfigure --priority=low unattended-upgrades

# mysql timezone loading
echo -e "${GR} * Loading timezone data into MySQL…${NC}"
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root mysql
service mysql restart

# mysql root user config
echo -e "${GR} * Configuring MySQL root user…${NC}"
read -s -p "Enter new MySQL root password: " MYSQLPASSWORD
echo ""
mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '$MYSQLPASSWORD'; FLUSH PRIVILEGES;"

# install Pillow/PIL dependencies
echo -e "${GR} * Installing Pillow dependencies…${NC}"
apt-get -y install libtiff5-dev libjpeg8-dev libopenjp2-7-dev zlib1g-dev libfreetype6-dev libwebp-dev

# cleanup
echo -e "${GR} * Cleaning up…${NC}"
apt-get -y autoremove
apt-get clean

# warn about ssh root login
echo ""
echo -e "${GR},--------------------------------------------------------------------.${NC}"
echo -e "${GR}|${NC} ${UND}You probably want to remove root's ability to log in via SSH!${NC}      ${GR}|${NC}"
echo -e "${GR}|${NC} To do so, add '${BLD}PermitRootLogin no${NC}' to ${BLD}/etc/ssh/sshd_config${NC}         ${GR}|${NC}"
echo -e "${GR}|${NC} Then restart ssh: # ${BLD}service ssh restart${NC}                            ${GR}|${NC}"
echo -e "${GR}\`--------------------------------------------------------------------'${NC}"
echo ""

# done
echo -e "${GR}Done! ${UND}Please reboot soon.${NOR} ${GR}Enjoy your new system!${NC}"
exit 0
