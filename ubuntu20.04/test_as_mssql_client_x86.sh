#!/bin/bash
clear
echo "To EXIT this script press  [ENTER]"
echo 
read -p "To RUN this script press  [Y]" -n 1 -r
echo
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi
#
### root check
if [[ "$EUID" -ne 0 ]]; then
	echo "Sorry, you need to run this as root"
	exit 1
fi
#
### base_setup check
if [[ -e /root/base_setup.README ]]; then
     echo "base_setup script installed - OK"
	 else
	 wget -O  base_setup.sh https://raw.githubusercontent.com/zzzkeil/base_setups/master/base_setup.sh
         chmod +x base_setup.sh
	 echo ""
	 echo ""
	 echo " Attention !!! "
	 echo " My base_setup script not installed,"
         echo " you have to run ./base_setup.sh manualy now and reboot, after that you can run this script again."
	 echo ""
	 echo ""
	 exit 1
fi
#
### OS version check
VERSION_ID=$(cat /etc/os-release | grep "VERSION_ID")

if [[ "$VERSION_ID" = 'VERSION_ID="20.04"' ]]; then
    echo " system is ubuntu 20.04 - ok lets go"
    else
    echo "sorry, this script is only for ubuntu 20.04"
    exit 1
fi
#

#
### wireguard port stettings
echo " Make your port settings now:"

echo "------------------------------------------------------------"
read -p "Choose your mssql Port: " -e -i 1433 dbport
echo "------------------------------------------------------------"
#
### apt systemupdate and installs	 
echo

apt update && apt upgrade -y && apt autoremove -y


### setup ufw 
ufw allow from 10.8.0.0/24 to any $dbport proto tcp

wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/20.04/mssql-server-2019.list)"
apt update
apt install mssql-server -y


/opt/mssql/bin/mssql-conf setup

systemctl stop mssql-server 


openssl req -x509 -nodes -newkey rsa:4096 -keyout mssql.key -out mssql.pem -days 365 
chown mssql:mssql mssql.pem mssql.key 
chmod 600 mssql.pem mssql.key 
mkdir /var/opt/mssql/certs/
mv mssql.pem /var/opt/mssql/certs/
mv mssql.key /var/opt/mssql/certs/


cat /var/opt/mssql/mssql.conf 
/opt/mssql/bin/mssql-conf set network.ipaddress 10.8.0.0
/opt/mssql/bin/mssql-conf set network.tcpport $dbport
/opt/mssql/bin/mssql-conf set network.tlscert /var/opt/mssql/certs/mssql.pem 
/opt/mssql/bin/mssql-conf set network.tlskey /var/opt/mssql/certs/mssql.key 
/opt/mssql/bin/mssql-conf set network.tlsprotocols 1.2
/opt/mssql/bin/mssql-conf set network.forceencryption 1
systemctl restart mssql-server 
