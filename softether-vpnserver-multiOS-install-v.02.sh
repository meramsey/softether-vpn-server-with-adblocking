#!/bin/bash
#SoftEther VPN Server install for Ubuntu/Debian/Centos.
# Copyleft (C) 2019 WhatTheServer - All Rights Reserved
# Permission to copy and modify is granted under the CopyLeft license

YUM_CMD=$(which yum)
APT_GET_CMD=$(which apt-get)

if [[ ! -z $YUM_CMD ]]; then
   yum update -y && yum upgrade -y && yum groupinstall -y "Development Tools" && yum install -y epel-release && yum install -y htop atop curl wget dnsmasq nano net-tools jq
   ZONE=$(firewall-cmd --get-default-zone)
   firewall-cmd --zone=$ZONE --add-service=openvpn --permanent
   firewall-cmd --zone=$ZONE --add-service=ipsec --permanent
   firewall-cmd --zone=$ZONE --add-service=https --permanent
   firewall-cmd --zone=$ZONE --add-port=992/tcp --permanent
   # 1194 UDP might not be opened
   # If you get TLS error, this may be the cause
   firewall-cmd --zone=$ZONE --add-port=1194/udp --permanent
   # NAT-T
   # Ref: https://blog.cles.jp/item/7295
   firewall-cmd --zone=$ZONE --add-port=500/udp --permanent
   firewall-cmd --zone=$ZONE --add-port=1701/udp --permanent
   firewall-cmd --zone=$ZONE --add-port=4500/udp --permanent
   # SoftEther
   firewall-cmd --zone=$ZONE --add-port=5555/tcp --permanent
   # For UDP Acceleration
   firewall-cmd --zone=$ZONE --add-port=40000-44999/udp --permanent
   firewall-cmd --reload
   touch /var/log/dnsmasq.log
   restorecon /var/log/dnsmasq.log
elif [[ ! -z $APT_GET_CMD ]]; then
   apt-get -y update && apt-get -y upgrade
   apt-get install -y build-essential dnsmasq htop atop python-simplejson python-minimal jq
   #disable and stop UFW firewall
   ufw disable; service ufw stop;
else
   echo "error can't install required packages. Unsupported OS"
   exit 1;
fi

#Backup dnsmasq conf
mv /etc/dnsmasq.conf /etc/dnsmasq.conf-bak

#Flush Iptables
iptables -F && iptables -X

#Grab latest Softether link for Linux x64 from here: http://www.softether-download.com/en.aspx?product=softether
SoftEtherWindowsManagerLatest=$(wget -q -nv -O- https://api.github.com/repos/SoftEtherVPN/SoftEtherVPN_Stable/releases/latest 2>/dev/null |  jq -r '.assets[] | select(.browser_download_url | contains("windows-x86_x64-intel")) | .browser_download_url')

SoftEtherLinuxLatest=$(wget -q -nv -O- https://api.github.com/repos/SoftEtherVPN/SoftEtherVPN_Stable/releases/latest 2>/dev/null |  jq -r '.assets[] | select(.browser_download_url | contains("linux-x64-64bit")) | .browser_download_url'| grep vpnserver)

latest_tag_url=$(curl -sI https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/releases/latest | grep -iE "^Location:"); echo "${latest_tag_url##*/}"
echo "Found $SoftEtherLinuxLatest"
echo "Installing: ${latest_tag_url##*/}"

#Use wget to copy it directly onto the server.
wget $SoftEtherLinuxLatest

#Extract it. Enter directory and run make and agree to all license agreements:
tar xvf softether-vpnserver-*.tar.gz
cd vpnserver
printf '1\n1\n1\n' | make

#Move up and then copy Softether libs to /usr/local
cd ..
mv vpnserver /usr/local
cd /usr/local/vpnserver/
chmod 600 *
chmod 700 vpncmd
chmod 700 vpnserver

# grab Softether vpn server.config template
wget -O /usr/local/vpnserver/vpn_server.config https://gitlab.com/mikeramsey/softether-vpn-server-with-adblocking/raw/master/vpn_server.config

#Generate random MAC for softether Tap Adapter vpn_server.config
export MAC=$(printf '%.2x\n' "$(shuf -i 0-281474976710655 -n 1)" | sed -r 's/(..)/\1:/g' | cut -d: -f -6 |  tr '[:lower:]' '[:upper:]')
echo $MAC

#change the default mac for TAP adapter in the config to a random one
sed -i "s/5E-BD-34-92-20-30/$MAC/g" /usr/local/vpnserver/vpn_server.config

#grab systemd unit file for SoftEther Service
wget -O /lib/systemd/system/vpnserver.service https://gitlab.com/mikeramsey/softether-vpn-server-with-adblocking/raw/master/vpnserver.service



#Setup DNSMasq

#grab dnsmasq conf
wget -O /etc/dnsmasq.conf https://gitlab.com/mikeramsey/softether-vpn-server-with-adblocking/raw/master/dnsmasq.conf

#To ensure clients leases are cleared if upgrading from standard VPN to say perfect dark have setup a dropin systemd unit file to clear leases on start/restart of dnsmasq file.
wget -O /etc/systemd/system/dnsmasq.service.d/clearlease.conf https://gitlab.com/mikeramsey/softether-vpn-server-with-adblocking/raw/master/dnsmasq.service_clearlease.conf

#grab current nic interface
NET_INTERFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)

echo "update interface in /etc/dnsmasq.conf to current: $NET_INTERFACE"
sed -i s/ens3/"$NET_INTERFACE"/g /etc/dnsmasq.conf

#ad blocking hosts
wget -O /root/updateHosts.sh https://gitlab.com/mikeramsey/softether-vpn-server-with-adblocking/-/raw/master/updateHosts.sh; chmod a+x /root/updateHosts.sh && bash /root/updateHosts.sh;

echo "Install adblocking cron"
command="/root/updateHosts.sh >/dev/null 2>&1"
job="0 0 * * * $command"
cat <(fgrep -i -v "$command" <(crontab -l)) <(echo "$job") | crontab -


echo "Install Log purging cron"
command2="find /usr/local/vpnserver/ -name '*.log' -delete; > /var/log/dnsmasq.log; >/dev/null 2>&1"
job2="* * * * * $command2"
cat <(fgrep -i -v "$command2" <(crontab -l)) <(echo "$job2") | crontab -


echo "Ipv4/IPv6 forwarding enabling /etc/sysctl.conf"
cat >> /etc/sysctl.conf <<EOL
net.core.somaxconn = 4096
net.ipv4.ip_forward = 1
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.send_redirects = 1
net.ipv4.conf.default.proxy_arp = 0
net.ipv6.conf.all.forwarding=1
net.ipv6.conf.default.forwarding = 1
net.ipv6.conf.tap_soft.accept_ra=2
net.ipv6.conf.all.accept_ra = 1
net.ipv6.conf.all.accept_source_route=1
net.ipv6.conf.all.accept_redirects = 1
net.ipv6.conf.all.proxy_ndp = 1
EOL
sysctl -f


#Grab base Sofether Iptables rules

#softether-iptables base rules
wget -O /root/softether-iptables.sh https://gitlab.com/mikeramsey/softether-vpn-server-with-adblocking/raw/master/softether-iptables.sh && chmod +x /root/softether-iptables.sh

#softether client_ports_iptables_conf.sh
wget -O /root/client_ports_iptables_conf.sh https://gitlab.com/mikeramsey/softether-vpn-server-with-adblocking/raw/master/client_ports_iptables_conf.sh  && chmod +x /root/client_ports_iptables_conf.sh

#Make ethers file for dnsmasq to do static assignments based on Mac Addresses: See example file https://gitlab.com/mikeramsey/softether-vpn-server-with-adblocking/raw/master/ethers
touch /etc/ethers

#To enable, start,and check status of the systemd dnsmasq dhcp service.
systemctl enable vpnserver dnsmasq
systemctl daemon-reload; systemctl stop dnsmasq.service; systemctl restart vpnserver;
systemctl status vpnserver dnsmasq;

#Regenerate selfsigned cert for vpn server from expect script
/usr/local/vpnserver/vpncmd /server localhost /password:softethervpn /cmd ServerCertRegenerate US
echo "==============================="
echo "Configuration files locations"
echo "Dnsmasq /etc/dnsmasq.conf"
echo "Iptables /root/softether-iptables.sh"
echo "SoftEther vpn_server.config /usr/local/vpnserver/vpn_server.config"
echo "Softether systemd service /lib/systemd/system/vpnserver.service"
echo "==============================="
echo "To enable, start,and check status of the systemd Softether vpn service."
echo "systemctl start vpnserver"
echo "systemctl stop vpnserver"
echo "systemctl restart vpnserver"
echo "systemctl status vpnserver"
echo "==============================="
echo "To enable, start,and check status of the systemd Dnsmasq DHCP service. This is autostarted by vpnserver service but if needed the below are the commands to manage it."
echo "systemctl start dnsmasq"
echo "systemctl stop dnsmasq"
echo "systemctl restart dnsmasq"
echo "systemctl status dnsmasq"
echo "==============================="
echo "Default vpn user is 'test' with password 'softethervpn'"
echo "Default Server administrator password is 'softethervpn'"
echo "To manage the server via Windows Server GUI grab the Server Manager client from $SoftEtherWindowsManagerLatest"
VPNEXTERNALIP=$(wget -qO- -t1 -T2 ipv4.icanhazip.com)
echo "Connect to $VPNEXTERNALIP:443"
echo "To connect to the VPN grab and install the softether vpn client from: https://www.softether-download.com/en.aspx?product=softether"
echo "Complete"
