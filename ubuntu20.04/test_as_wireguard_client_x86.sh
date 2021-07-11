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
### script already installed check
if [[ -e /root/wireguard-mssql-Server.README ]]; then
	 exit 1
fi
#
### create backupfolder for original files
mkdir /root/script_backupfiles/
#
### wireguard port stettings
echo " Make wireguard client settings now:"
echo "------------------------------------------------------------"
read -p "Enter your wireguard client ip (ipv4): " -e -i 10.8.0.200/32 wg0clientip
echo "------------------------------------------------------------"
echo
echo "------------------------------------------------------------"
read -p "Enter your wireguard client privatekey: " -e -i wJtNUga...... wg0clkey
echo "------------------------------------------------------------"
echo
echo "------------------------------------------------------------"
read -p "Enter your wireguard endpiont ip: " -e -i 000.000.000.000 wg0endip
echo "------------------------------------------------------------"
echo
echo "------------------------------------------------------------"
read -p "Enter your wireguard endpiont port: " -e -i 54321 wg0port
echo "------------------------------------------------------------"
echo
echo "------------------------------------------------------------"
read -p "Enter your wireguard endpoints puplickey: " -e -i zTtm9AvC...... wg0pupkey
echo "------------------------------------------------------------"
echo
echo "------------------------------------------------------------"
read -p "Enter your allowed ips : " -e -i 10.8.0.0/24 wg0allowed
echo "------------------------------------------------------------"
echo
echo "------------------------------------------------------------"
read -p "Enter your PersistentKeepalive  : " -e -i 25 wg0keepa
echo "------------------------------------------------------------"
echo
echo " Make your mssql port settings now:"
echo "------------------------------------------------------------"
read -p "Choose your mssql Port: " -e -i 1433 dbport
echo "------------------------------------------------------------"
#
### apt systemupdate and installs	 


apt update && apt upgrade -y && apt autoremove -y
apt install qrencode python curl linux-headers-$(uname -r) -y 
apt install wireguard-dkms wireguard-tools -y
#
### setup ufw 

ufw allow in on wg0 to any port $dbport


#
### setup wireguard keys and configs

echo "
[Interface]
Address = $wg0clientip
PrivateKey = $wg0clkey
[Peer]
Endpoint = $wg0endip:$wg0endip
PublicKey = $wg0pupkey
AllowedIPs = $wg0allowed
PersistentKeepalive = $wg0keepa
" > /etc/wireguard/wg0.conf

chmod 600 /etc/wireguard/wg0.conf



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
/opt/mssql/bin/mssql-conf set network.tcpport $dbport
/opt/mssql/bin/mssql-conf set network.tlscert /var/opt/mssql/certs/mssql.pem 
/opt/mssql/bin/mssql-conf set network.tlskey /var/opt/mssql/certs/mssql.key 
/opt/mssql/bin/mssql-conf set network.tlsprotocols 1.2
/opt/mssql/bin/mssql-conf set network.forceencryption 1
systemctl restart mssql-server 


systemctl restart mssql-server
systemctl enable wg-quick@wg0.service
systemctl start wg-quick@wg0.service


ln -s /etc/wireguard/ /root/wireguard_folder
ln -s /var/opt/mssql/ /root/mssql_folder
clear
ufw --force enable
ufw reload

