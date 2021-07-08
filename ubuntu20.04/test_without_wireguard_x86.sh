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
if [[ -e /etc/debian_version ]]; then
      echo "Debian Distribution"
      else
      echo "This is not a Debian Distribution."
      exit 1
fi
#
### script already installed check
if [[ -e /root/wireguard-mssql-Server.README ]]; then
	 exit 1
fi
#
### create backupfolder for original files
mkdir /root/script_backupfiles/
#
### wireguard port stettings
echo " Make your port settings now:"

echo "------------------------------------------------------------"
read -p "Choose your mssql Port: " -e -i 1433 dbport
echo "------------------------------------------------------------"
#
### apt systemupdate and installs	 
echo
VERSION_ID=$(cat /etc/os-release | grep "VERSION_ID")
if [[ "$VERSION_ID" = 'VERSION_ID="10"' ]]; then
	echo "deb http://deb.debian.org/debian/ unstable main" > /etc/apt/sources.list.d/unstable-wireguard.list
        printf 'Package: *\nPin: release a=unstable\nPin-Priority: 150\n' > /etc/apt/preferences.d/limit-unstable
fi

if [[ "$VERSION_ID" = 'VERSION_ID="18.04"' ]]; then
    add-apt-repository ppa:wireguard/wireguard
fi

if [[ "$VERSION_ID" = 'VERSION_ID="20.04"' ]]; then
    echo " system is ubuntu 20.04"
fi

apt update && apt upgrade -y && apt autoremove -y


### setup ufw 
ufw allow $dbport

wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/20.04/mssql-server-2019.list)"
apt update
apt install mssql-server -y


/opt/mssql/bin/mssql-conf setup

systemctl stop mssql-server 

/opt/mssql/bin/mssql-conf set network.tcpport $dbport


openssl req -x509 -nodes -newkey rsa:4096 -keyout mssql.key -out mssql.pem -days 365 
chown mssql:mssql mssql.pem mssql.key 
chmod 600 mssql.pem mssql.key 
mv mssql.pem /var/opt/mssql/certs/
mv mssql.key /var/opt/mssql/certs/


cat /var/opt/mssql/mssql.conf 
/opt/mssql/bin/mssql-conf set network.tlscert /var/opt/mssql/certs/mssql.pem 
/opt/mssql/bin/mssql-conf set network.tlskey /var/opt/mssql/certs/mssql.key 
/opt/mssql/bin/mssql-conf set network.tlsprotocols 1.2
/opt/mssql/bin/mssql-conf set network.forceencryption 1
systemctl restart mssql-server 





