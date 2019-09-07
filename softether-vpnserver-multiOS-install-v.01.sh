#!/bin/bash
#SoftEther VPN Server install for Ubuntu/Debian/Centos.
# Copyleft (C) 2019 WhatTheServer - All Rights Reserved
# Permission to copy and modify is granted under the CopyLeft license

YUM_CMD=$(which yum)
APT_GET_CMD=$(which apt-get)

if [[ ! -z $YUM_CMD ]]; then
   yum update -y && yum upgrade -y && yum groupinstall -y "Development Tools" && yum install -y epel-release && yum install -y htop atop curl wget dnsmasq nano net-tools
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
   apt-get install -y build-essential dnsmasq htop atop python-simplejson python-minimal
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

#Use wget to copy it directly onto the server.
wget https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/releases/download/v4.30-9696-beta/softether-vpnserver-v4.30-9696-beta-2019.07.08-linux-x64-64bit.tar.gz

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

#create Softether vpn server.config template
touch /usr/local/vpnserver/vpn_server.config
echo '# Software Configuration File'>> /usr/local/vpnserver/vpn_server.config
echo '# ---------------------------'>> /usr/local/vpnserver/vpn_server.config
echo '# '>> /usr/local/vpnserver/vpn_server.config
echo '# You may edit this file when the VPN Server / Client / Bridge program is not running.'>> /usr/local/vpnserver/vpn_server.config
echo '# '>> /usr/local/vpnserver/vpn_server.config
echo '# In prior to edit this file manually by your text editor,'>> /usr/local/vpnserver/vpn_server.config
echo '# shutdown the VPN Server / Client / Bridge background service.'>> /usr/local/vpnserver/vpn_server.config
echo '# Otherwise, all changes will be lost.'>> /usr/local/vpnserver/vpn_server.config
echo '# '>> /usr/local/vpnserver/vpn_server.config
echo 'declare root'>> /usr/local/vpnserver/vpn_server.config
echo '{'>> /usr/local/vpnserver/vpn_server.config
echo '	uint ConfigRevision 103'>> /usr/local/vpnserver/vpn_server.config
echo '	bool IPsecMessageDisplayed true'>> /usr/local/vpnserver/vpn_server.config
echo '	string Region NL'>> /usr/local/vpnserver/vpn_server.config
echo '	bool VgsMessageDisplayed false'>> /usr/local/vpnserver/vpn_server.config
echo ''>> /usr/local/vpnserver/vpn_server.config
echo '	declare DDnsClient'>> /usr/local/vpnserver/vpn_server.config
echo '	{'>> /usr/local/vpnserver/vpn_server.config
echo '		bool Disabled false'>> /usr/local/vpnserver/vpn_server.config
echo '		byte Key XU8vewLHvS7FoP/8OwS5n6icav0='>> /usr/local/vpnserver/vpn_server.config
echo '		string LocalHostname softethervpn'>> /usr/local/vpnserver/vpn_server.config
echo '		string ProxyHostName $'>> /usr/local/vpnserver/vpn_server.config
echo '		uint ProxyPort 0'>> /usr/local/vpnserver/vpn_server.config
echo '		uint ProxyType 0'>> /usr/local/vpnserver/vpn_server.config
echo '		string ProxyUsername $'>> /usr/local/vpnserver/vpn_server.config
echo '	}'>> /usr/local/vpnserver/vpn_server.config
echo '	declare IPsec'>> /usr/local/vpnserver/vpn_server.config
echo '	{'>> /usr/local/vpnserver/vpn_server.config
echo '		bool EtherIP_IPsec false'>> /usr/local/vpnserver/vpn_server.config
echo '		string IPsec_Secret vpn'>> /usr/local/vpnserver/vpn_server.config
echo '		string L2TP_DefaultHub VPN'>> /usr/local/vpnserver/vpn_server.config
echo '		bool L2TP_IPsec true'>> /usr/local/vpnserver/vpn_server.config
echo '		bool L2TP_Raw false'>> /usr/local/vpnserver/vpn_server.config
echo ''>> /usr/local/vpnserver/vpn_server.config
echo '		declare EtherIP_IDSettingsList'>> /usr/local/vpnserver/vpn_server.config
echo '		{'>> /usr/local/vpnserver/vpn_server.config
echo '		}'>> /usr/local/vpnserver/vpn_server.config
echo '	}'>> /usr/local/vpnserver/vpn_server.config
echo '	declare ListenerList'>> /usr/local/vpnserver/vpn_server.config
echo '	{'>> /usr/local/vpnserver/vpn_server.config
echo '		declare Listener0'>> /usr/local/vpnserver/vpn_server.config
echo '		{'>> /usr/local/vpnserver/vpn_server.config
echo '			bool DisableDos false'>> /usr/local/vpnserver/vpn_server.config
echo '			bool Enabled true'>> /usr/local/vpnserver/vpn_server.config
echo '			uint Port 443'>> /usr/local/vpnserver/vpn_server.config
echo '		}'>> /usr/local/vpnserver/vpn_server.config
echo '		declare Listener1'>> /usr/local/vpnserver/vpn_server.config
echo '		{'>> /usr/local/vpnserver/vpn_server.config
echo '			bool DisableDos false'>> /usr/local/vpnserver/vpn_server.config
echo '			bool Enabled true'>> /usr/local/vpnserver/vpn_server.config
echo '			uint Port 992'>> /usr/local/vpnserver/vpn_server.config
echo '		}'>> /usr/local/vpnserver/vpn_server.config
echo '		declare Listener2'>> /usr/local/vpnserver/vpn_server.config
echo '		{'>> /usr/local/vpnserver/vpn_server.config
echo '			bool DisableDos false'>> /usr/local/vpnserver/vpn_server.config
echo '			bool Enabled true'>> /usr/local/vpnserver/vpn_server.config
echo '			uint Port 1194'>> /usr/local/vpnserver/vpn_server.config
echo '		}'>> /usr/local/vpnserver/vpn_server.config
echo '		declare Listener3'>> /usr/local/vpnserver/vpn_server.config
echo '		{'>> /usr/local/vpnserver/vpn_server.config
echo '			bool DisableDos false'>> /usr/local/vpnserver/vpn_server.config
echo '			bool Enabled true'>> /usr/local/vpnserver/vpn_server.config
echo '			uint Port 5555'>> /usr/local/vpnserver/vpn_server.config
echo '		}'>> /usr/local/vpnserver/vpn_server.config
echo '	}'>> /usr/local/vpnserver/vpn_server.config
echo '	declare LocalBridgeList'>> /usr/local/vpnserver/vpn_server.config
echo '	{'>> /usr/local/vpnserver/vpn_server.config
echo '		bool DoNotDisableOffloading false'>> /usr/local/vpnserver/vpn_server.config
echo ''>> /usr/local/vpnserver/vpn_server.config
echo '		declare LocalBridge0'>> /usr/local/vpnserver/vpn_server.config
echo '		{'>> /usr/local/vpnserver/vpn_server.config
echo '			string DeviceName soft'>> /usr/local/vpnserver/vpn_server.config
echo '			string HubName VPN'>> /usr/local/vpnserver/vpn_server.config
echo '			bool LimitBroadcast false'>> /usr/local/vpnserver/vpn_server.config
echo '			bool MonitorMode false'>> /usr/local/vpnserver/vpn_server.config
echo '			bool NoPromiscuousMode false'>> /usr/local/vpnserver/vpn_server.config
echo '			string TapMacAddress 5E-BD-34-92-20-30'>> /usr/local/vpnserver/vpn_server.config
echo '			bool TapMode true'>> /usr/local/vpnserver/vpn_server.config
echo '		}'>> /usr/local/vpnserver/vpn_server.config
echo '	}'>> /usr/local/vpnserver/vpn_server.config
echo '	declare ServerConfiguration'>> /usr/local/vpnserver/vpn_server.config
echo '	{'>> /usr/local/vpnserver/vpn_server.config
echo '		bool AcceptOnlyTls true'>> /usr/local/vpnserver/vpn_server.config
echo '		uint64 AutoDeleteCheckDiskFreeSpaceMin 104857600'>> /usr/local/vpnserver/vpn_server.config
echo '		uint AutoDeleteCheckIntervalSecs 300'>> /usr/local/vpnserver/vpn_server.config
echo '		uint AutoSaveConfigSpan 300'>> /usr/local/vpnserver/vpn_server.config
echo '		bool BackupConfigOnlyWhenModified true'>> /usr/local/vpnserver/vpn_server.config
echo '		string CipherName ECDHE-RSA-AES256-GCM-SHA384'>> /usr/local/vpnserver/vpn_server.config
echo '		uint CurrentBuild 9680'>> /usr/local/vpnserver/vpn_server.config
echo '		bool DisableCoreDumpOnUnix false'>> /usr/local/vpnserver/vpn_server.config
echo '		bool DisableDeadLockCheck false'>> /usr/local/vpnserver/vpn_server.config
echo '		bool DisableDosProction false'>> /usr/local/vpnserver/vpn_server.config
echo '		bool DisableGetHostNameWhenAcceptTcp false'>> /usr/local/vpnserver/vpn_server.config
echo '		bool DisableIntelAesAcceleration false'>> /usr/local/vpnserver/vpn_server.config
echo '		bool DisableIPv6Listener false'>> /usr/local/vpnserver/vpn_server.config
echo '		bool DisableNatTraversal false'>> /usr/local/vpnserver/vpn_server.config
echo '		bool DisableOpenVPNServer false'>> /usr/local/vpnserver/vpn_server.config
echo '		bool DisableSessionReconnect false'>> /usr/local/vpnserver/vpn_server.config
echo '		bool DisableSSTPServer false'>> /usr/local/vpnserver/vpn_server.config
echo '		bool DontBackupConfig false'>> /usr/local/vpnserver/vpn_server.config
echo '		bool EnableVpnAzure false'>> /usr/local/vpnserver/vpn_server.config
echo '		bool EnableVpnOverDns false'>> /usr/local/vpnserver/vpn_server.config
echo '		bool EnableVpnOverIcmp false'>> /usr/local/vpnserver/vpn_server.config
echo '		byte HashedPassword 1HfnCHtpiTmGZZp0BbagF0LG+P0='>> /usr/local/vpnserver/vpn_server.config
echo '		string KeepConnectHost keepalive.softether.org'>> /usr/local/vpnserver/vpn_server.config
echo '		uint KeepConnectInterval 50'>> /usr/local/vpnserver/vpn_server.config
echo '		uint KeepConnectPort 80'>> /usr/local/vpnserver/vpn_server.config
echo '		uint KeepConnectProtocol 1'>> /usr/local/vpnserver/vpn_server.config
echo '		uint64 LoggerMaxLogSize 1073741823'>> /usr/local/vpnserver/vpn_server.config
echo '		uint MaxConcurrentDnsClientThreads 512'>> /usr/local/vpnserver/vpn_server.config
echo '		uint MaxConnectionsPerIP 256'>> /usr/local/vpnserver/vpn_server.config
echo '		uint MaxUnestablishedConnections 1000'>> /usr/local/vpnserver/vpn_server.config
echo '		bool NoHighPriorityProcess false'>> /usr/local/vpnserver/vpn_server.config
echo '		bool NoLinuxArpFilter false'>> /usr/local/vpnserver/vpn_server.config
echo '		bool NoSendSignature false'>> /usr/local/vpnserver/vpn_server.config
echo '		string OpenVPNDefaultClientOption dev-type$20tun,link-mtu$201500,tun-mtu$201500,cipher$20AES-128-CBC,auth$20SHA1,keysize$20128,key-method$202,tls-client'>> /usr/local/vpnserver/vpn_server.config
echo '		string OpenVPN_UdpPortList 443,$201194'>> /usr/local/vpnserver/vpn_server.config
echo '		bool SaveDebugLog false'>> /usr/local/vpnserver/vpn_server.config
echo '		byte ServerCert MIID+jCCAuKgAwIBAgIBADANBgkqhkiG9w0BAQsFADB8MSMwIQYDVQQDDBp2cG4zMzI4MTA5MjQuc29mdGV0aGVyLm5ldDEjMCEGA1UECgwadnBuMzMyODEwOTI0LnNvZnRldGhlci5uZXQxIzAhBgNVBAsMGnZwbjMzMjgxMDkyNC5zb2Z0ZXRoZXIubmV0MQswCQYDVQQGEwJVUzAeFw0xOTA0MDgxNTM5NDlaFw0zNzEyMzExNTM5NDlaMHwxIzAhBgNVBAMMGnZwbjMzMjgxMDkyNC5zb2Z0ZXRoZXIubmV0MSMwIQYDVQQKDBp2cG4zMzI4MTA5MjQuc29mdGV0aGVyLm5ldDEjMCEGA1UECwwadnBuMzMyODEwOTI0LnNvZnRldGhlci5uZXQxCzAJBgNVBAYTAlVTMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4COf2Um0x7szRipZGQpH4pkdRnb6KYbEjzZ6UBlEMoJsLbolxK5kcsOGC3wFVV4aP237mUhYdu12iq15LwJXxyUj/XccyGVYGAcOGmIe4dMJSG1BHRV+M2XwAO8BT+jhZXkmeVtOG3qiTxa1COi6Yk3Z01DmtoZ9i0bN/716ZSgs5D3aW7sP+KvvPYvuNdZkZPM184ou+T2IA91fEwBwB5fK1Z04bkG04wuts08Rv5ZVvbnF/NkUQ86pR9yxd1rQDZ9FpbC6xRSCPQymdIIpEXgIZfe1jxH/MV6SOb4fM1jjRZVN5fhZGdsmSwAYSu1Dac8LheK0qmaeMCmCeqdg+QIDAQABo4GGMIGDMA8GA1UdEwEB/wQFMAMBAf8wCwYDVR0PBAQDAgH2MGMGA1UdJQRcMFoGCCsGAQUFBwMBBggrBgEFBQcDAgYIKwYBBQUHAwMGCCsGAQUFBwMEBggrBgEFBQcDBQYIKwYBBQUHAwYGCCsGAQUFBwMHBggrBgEFBQcDCAYIKwYBBQUHAwkwDQYJKoZIhvcNAQELBQADggEBAAscfcgk+Q5Nbh2ok+h1o5I4cBI2t54nqsq8d04MOqcJCZPzplMc5kIPTLR0TX0c2Wtx0ZUREVVvEUhU+vXe8JCRBu9q4xEgb23jtxSE/w96uhcdT/r2lJ6cTHnHSuK+tBb/JR0TdVYTYAWGObDa8umodNsPnd/x4j3uW8AGqqDkYhfHkwcvQwbEt33oNngX2Mldb6q6R9jW8qFBrZHNgRrmsXZA+si2orUQNvz4CsZwT9jQSVS/TKtW5XCwdgx/gp/Ex7vC5mzIf2+rx498gEmcfUrJuecQJHCXAeXu5OyXEMMoOwChiz8YOPgO5blj7RaqC/L5JnA9T3Ol/D1Nt20='>> /usr/local/vpnserver/vpn_server.config
echo '		byte ServerKey MIIEowIBAAKCAQEA4COf2Um0x7szRipZGQpH4pkdRnb6KYbEjzZ6UBlEMoJsLbolxK5kcsOGC3wFVV4aP237mUhYdu12iq15LwJXxyUj/XccyGVYGAcOGmIe4dMJSG1BHRV+M2XwAO8BT+jhZXkmeVtOG3qiTxa1COi6Yk3Z01DmtoZ9i0bN/716ZSgs5D3aW7sP+KvvPYvuNdZkZPM184ou+T2IA91fEwBwB5fK1Z04bkG04wuts08Rv5ZVvbnF/NkUQ86pR9yxd1rQDZ9FpbC6xRSCPQymdIIpEXgIZfe1jxH/MV6SOb4fM1jjRZVN5fhZGdsmSwAYSu1Dac8LheK0qmaeMCmCeqdg+QIDAQABAoIBAH5WFieXz/o0njYScJ4YmWQ0AbhSH7eAaxJ+FntHgpUlxmwP3HH8CkpVwxx+D1OK8yiFiadgi9ydBJAuL3w7ydZKLPsVRHgAB6OjdmOQou+O0FCupGEMWFIIRzt/fDHahhF4NCN7P49llE8X8XrQEx6N2xWtKB4BuInkowBfgLm62WM3OXiemEcUCwEUCI+Fl+PQ4KMTK8xLcXjD0sT6Lqwve+rucN2fdwqFRHS9+nyczvO6ZVMoxPKRDEngr3HJnq6JXkd7PUoeRP4/iJNLkZJun9w0WBNfLLbOwIsTG0i9LqYIsangWajSjAkEyYN06Z+qhprgCQDf6YalOBXiDbECgYEA8qgBPiwSV7a/NYgmf7dmfVcrcn4tLZAT9hLeGFBAq46s4IcxK4sFev2I9rosKIa/+da13Vx9lanI8AHk+5gY7SGnuVZ+qHKY2k6sFNkn/KUPiCRQPccDppGD77LuSPVY8Xza0c85cikkYxCptt27H6AAtV6O1oip16ZX1ERdwBsCgYEA7Hbx3tr42pd+/iSeOEaCer1UajLHmWEEjQF0SdUJwZnHg+rVTpXIEnbK0rw+uFw90L2624gPQxcOaIC6hZflqBj1DC3BBYGAEdkcojg45xuoGpzv0Rlr2ObZq00nxzDie0/Cm+TyDMVUZ2R3koShdVagMZSVgtBQyXya4ridfHsCgYEA6sq/MR5JvU+ZYj3UKp4V8E/JPWZzZnPTrLWC6vm0KYvLIRIO9Lf23JO31Cw+EBSaay9jF8anyYnYYMskeoEoFUMMXFwh//GqjwmynhWlCGPaTHv+nFgV4zVH+UYkJLopjrilrn+ZcSn4CFcWMFgJ+MbECLpu8YyY8o4Ey+I+6GMCgYAQiiFQ3TAa2g3f6N/IP+ZQf32wD+02JTsUQc3IfEY6bG8wIvTYklF0OSrmopQggRMxzpOLV3D52FsBpD9nqMA/ib9aIrklkXFLzkvabOROBfk0I1YC4ixQ95SyDquBm0G8LlAGZ3Umv4av1K8oaG6CrpR141ax17BO55BN22vokQKBgG6rAm+z9RZiuBF+eIvWsZ77qlei2XuVyaAcf8M9VkBwkekD/M6NOQ74nLaNsqUfX0aMQ+gX/lF04yipqLD22TiqneiuEc7SSlaG2G78Lv4Rm4Jv/scQI7omS5qRqchFBWMDYLrM2l7M+bppy2IlnGtijHpC1NH5ELbtSHd9OL75'>> /usr/local/vpnserver/vpn_server.config
echo '		uint ServerLogSwitchType 4'>> /usr/local/vpnserver/vpn_server.config
echo '		uint ServerType 0'>> /usr/local/vpnserver/vpn_server.config
echo '		bool StrictSyslogDatetimeFormat false'>> /usr/local/vpnserver/vpn_server.config
echo '		bool Tls_Disable1_0 false'>> /usr/local/vpnserver/vpn_server.config
echo '		bool Tls_Disable1_1 false'>> /usr/local/vpnserver/vpn_server.config
echo '		bool Tls_Disable1_2 false'>> /usr/local/vpnserver/vpn_server.config
echo '		bool UseKeepConnect true'>> /usr/local/vpnserver/vpn_server.config
echo '		bool UseWebTimePage false'>> /usr/local/vpnserver/vpn_server.config
echo '		bool UseWebUI false'>> /usr/local/vpnserver/vpn_server.config
echo ''>> /usr/local/vpnserver/vpn_server.config
echo '		declare GlobalParams'>> /usr/local/vpnserver/vpn_server.config
echo '		{'>> /usr/local/vpnserver/vpn_server.config
echo '			uint FIFO_BUDGET 10240000'>> /usr/local/vpnserver/vpn_server.config
echo '			uint HUB_ARP_SEND_INTERVAL 5000'>> /usr/local/vpnserver/vpn_server.config
echo '			uint IP_TABLE_EXPIRE_TIME 60000'>> /usr/local/vpnserver/vpn_server.config
echo '			uint IP_TABLE_EXPIRE_TIME_DHCP 300000'>> /usr/local/vpnserver/vpn_server.config
echo '			uint MAC_TABLE_EXPIRE_TIME 600000'>> /usr/local/vpnserver/vpn_server.config
echo '			uint MAX_BUFFERING_PACKET_SIZE 2560000'>> /usr/local/vpnserver/vpn_server.config
echo '			uint MAX_HUB_LINKS 1024'>> /usr/local/vpnserver/vpn_server.config
echo '			uint MAX_IP_TABLES 65536'>> /usr/local/vpnserver/vpn_server.config
echo '			uint MAX_MAC_TABLES 65536'>> /usr/local/vpnserver/vpn_server.config
echo '			uint MAX_SEND_SOCKET_QUEUE_NUM 128'>> /usr/local/vpnserver/vpn_server.config
echo '			uint MAX_SEND_SOCKET_QUEUE_SIZE 2560000'>> /usr/local/vpnserver/vpn_server.config
echo '			uint MAX_STORED_QUEUE_NUM 1024'>> /usr/local/vpnserver/vpn_server.config
echo '			uint MEM_FIFO_REALLOC_MEM_SIZE 655360'>> /usr/local/vpnserver/vpn_server.config
echo '			uint MIN_SEND_SOCKET_QUEUE_SIZE 320000'>> /usr/local/vpnserver/vpn_server.config
echo '			uint QUEUE_BUDGET 2048'>> /usr/local/vpnserver/vpn_server.config
echo '			uint SELECT_TIME 256'>> /usr/local/vpnserver/vpn_server.config
echo '			uint SELECT_TIME_FOR_NAT 30'>> /usr/local/vpnserver/vpn_server.config
echo '			uint STORM_CHECK_SPAN 500'>> /usr/local/vpnserver/vpn_server.config
echo '			uint STORM_DISCARD_VALUE_END 1024'>> /usr/local/vpnserver/vpn_server.config
echo '			uint STORM_DISCARD_VALUE_START 3'>> /usr/local/vpnserver/vpn_server.config
echo '		}'>> /usr/local/vpnserver/vpn_server.config
echo '		declare ServerTraffic'>> /usr/local/vpnserver/vpn_server.config
echo '		{'>> /usr/local/vpnserver/vpn_server.config
echo '			declare RecvTraffic'>> /usr/local/vpnserver/vpn_server.config
echo '			{'>> /usr/local/vpnserver/vpn_server.config
echo '				uint64 BroadcastBytes 11338463'>> /usr/local/vpnserver/vpn_server.config
echo '				uint64 BroadcastCount 156886'>> /usr/local/vpnserver/vpn_server.config
echo '				uint64 UnicastBytes 82781105'>> /usr/local/vpnserver/vpn_server.config
echo '				uint64 UnicastCount 960702'>> /usr/local/vpnserver/vpn_server.config
echo '			}'>> /usr/local/vpnserver/vpn_server.config
echo '			declare SendTraffic'>> /usr/local/vpnserver/vpn_server.config
echo '			{'>> /usr/local/vpnserver/vpn_server.config
echo '				uint64 BroadcastBytes 12369231'>> /usr/local/vpnserver/vpn_server.config
echo '				uint64 BroadcastCount 171224'>> /usr/local/vpnserver/vpn_server.config
echo '				uint64 UnicastBytes 31309285'>> /usr/local/vpnserver/vpn_server.config
echo '				uint64 UnicastCount 355764'>> /usr/local/vpnserver/vpn_server.config
echo '			}'>> /usr/local/vpnserver/vpn_server.config
echo '		}'>> /usr/local/vpnserver/vpn_server.config
echo '		declare SyslogSettings'>> /usr/local/vpnserver/vpn_server.config
echo '		{'>> /usr/local/vpnserver/vpn_server.config
echo '			string HostName $'>> /usr/local/vpnserver/vpn_server.config
echo '			uint Port 514'>> /usr/local/vpnserver/vpn_server.config
echo '			uint SaveType 0'>> /usr/local/vpnserver/vpn_server.config
echo '		}'>> /usr/local/vpnserver/vpn_server.config
echo '	}'>> /usr/local/vpnserver/vpn_server.config
echo '	declare VirtualHUB'>> /usr/local/vpnserver/vpn_server.config
echo '	{'>> /usr/local/vpnserver/vpn_server.config
echo '		declare VPN'>> /usr/local/vpnserver/vpn_server.config
echo '		{'>> /usr/local/vpnserver/vpn_server.config
echo '			uint64 CreatedTime 1554705556030'>> /usr/local/vpnserver/vpn_server.config
echo '			byte HashedPassword 1HfnCHtpiTmGZZp0BbagF0LG+P0='>> /usr/local/vpnserver/vpn_server.config
echo '			uint64 LastCommTime 1555041608901'>> /usr/local/vpnserver/vpn_server.config
echo '			uint64 LastLoginTime 1554715032217'>> /usr/local/vpnserver/vpn_server.config
echo '			uint NumLogin 4'>> /usr/local/vpnserver/vpn_server.config
echo '			bool Online true'>> /usr/local/vpnserver/vpn_server.config
echo '			bool RadiusConvertAllMsChapv2AuthRequestToEap false'>> /usr/local/vpnserver/vpn_server.config
echo '			string RadiusRealm $'>> /usr/local/vpnserver/vpn_server.config
echo '			uint RadiusRetryInterval 0'>> /usr/local/vpnserver/vpn_server.config
echo '			uint RadiusServerPort 1812'>> /usr/local/vpnserver/vpn_server.config
echo '			string RadiusSuffixFilter $'>> /usr/local/vpnserver/vpn_server.config
echo '			bool RadiusUsePeapInsteadOfEap false'>> /usr/local/vpnserver/vpn_server.config
echo '			byte SecurePassword 5rYHyje4qZ3UnpHUccuJAq5QspY='>> /usr/local/vpnserver/vpn_server.config
echo '			uint Type 0'>> /usr/local/vpnserver/vpn_server.config
echo ''>> /usr/local/vpnserver/vpn_server.config
echo '			declare AccessList'>> /usr/local/vpnserver/vpn_server.config
echo '			{'>> /usr/local/vpnserver/vpn_server.config
echo '			}'>> /usr/local/vpnserver/vpn_server.config
echo '			declare AdminOption'>> /usr/local/vpnserver/vpn_server.config
echo '			{'>> /usr/local/vpnserver/vpn_server.config
echo '				uint allow_hub_admin_change_option 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint deny_bridge 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint deny_change_user_password 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint deny_empty_password 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint deny_hub_admin_change_ext_option 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint deny_qos 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint deny_routing 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint max_accesslists 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint max_bitrates_download 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint max_bitrates_upload 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint max_groups 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint max_multilogins_per_user 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint max_sessions 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint max_sessions_bridge 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint max_sessions_client 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint max_sessions_client_bridge_apply 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint max_users 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint no_access_list_include_file 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint no_cascade 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint no_change_access_control_list 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint no_change_access_list 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint no_change_admin_password 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint no_change_cert_list 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint no_change_crl_list 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint no_change_groups 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint no_change_log_config 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint no_change_log_switch_type 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint no_change_msg 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint no_change_users 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint no_delay_jitter_packet_loss 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint no_delete_iptable 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint no_delete_mactable 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint no_disconnect_session 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint no_enum_session 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint no_offline 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint no_online 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint no_query_session 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint no_read_log_file 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint no_securenat 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint no_securenat_enabledhcp 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint no_securenat_enablenat 0'>> /usr/local/vpnserver/vpn_server.config
echo '			}'>> /usr/local/vpnserver/vpn_server.config
echo '			declare CascadeList'>> /usr/local/vpnserver/vpn_server.config
echo '			{'>> /usr/local/vpnserver/vpn_server.config
echo '			}'>> /usr/local/vpnserver/vpn_server.config
echo '			declare LogSetting'>> /usr/local/vpnserver/vpn_server.config
echo '			{'>> /usr/local/vpnserver/vpn_server.config
echo '				uint PacketLogSwitchType 4'>> /usr/local/vpnserver/vpn_server.config
echo '				uint PACKET_LOG_ARP 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint PACKET_LOG_DHCP 1'>> /usr/local/vpnserver/vpn_server.config
echo '				uint PACKET_LOG_ETHERNET 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint PACKET_LOG_ICMP 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint PACKET_LOG_IP 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint PACKET_LOG_TCP 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint PACKET_LOG_TCP_CONN 1'>> /usr/local/vpnserver/vpn_server.config
echo '				uint PACKET_LOG_UDP 0'>> /usr/local/vpnserver/vpn_server.config
echo '				bool SavePacketLog false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool SaveSecurityLog false'>> /usr/local/vpnserver/vpn_server.config
echo '				uint SecurityLogSwitchType 4'>> /usr/local/vpnserver/vpn_server.config
echo '			}'>> /usr/local/vpnserver/vpn_server.config
echo '			declare Message'>> /usr/local/vpnserver/vpn_server.config
echo '			{'>> /usr/local/vpnserver/vpn_server.config
echo '			}'>> /usr/local/vpnserver/vpn_server.config
echo '			declare Option'>> /usr/local/vpnserver/vpn_server.config
echo '			{'>> /usr/local/vpnserver/vpn_server.config
echo '				uint AccessListIncludeFileCacheLifetime 30'>> /usr/local/vpnserver/vpn_server.config
echo '				uint AdjustTcpMssValue 0'>> /usr/local/vpnserver/vpn_server.config
echo '				bool ApplyIPv4AccessListOnArpPacket false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool AssignVLanIdByRadiusAttribute false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool BroadcastLimiterStrictMode false'>> /usr/local/vpnserver/vpn_server.config
echo '				uint BroadcastStormDetectionThreshold 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint ClientMinimumRequiredBuild 0'>> /usr/local/vpnserver/vpn_server.config
echo '				bool DenyAllRadiusLoginWithNoVlanAssign false'>> /usr/local/vpnserver/vpn_server.config
echo '				uint DetectDormantSessionInterval 0'>> /usr/local/vpnserver/vpn_server.config
echo '				bool DisableAdjustTcpMss false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool DisableCheckMacOnLocalBridge false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool DisableCorrectIpOffloadChecksum false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool DisableHttpParsing false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool DisableIPParsing false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool DisableIpRawModeSecureNAT false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool DisableKernelModeSecureNAT false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool DisableUdpAcceleration false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool DisableUdpFilterForLocalBridgeNic false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool DisableUserModeSecureNAT false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool DoNotSaveHeavySecurityLogs false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool DropArpInPrivacyFilterMode true'>> /usr/local/vpnserver/vpn_server.config
echo '				bool DropBroadcastsInPrivacyFilterMode true'>> /usr/local/vpnserver/vpn_server.config
echo '				bool FilterBPDU false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool FilterIPv4 false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool FilterIPv6 false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool FilterNonIP false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool FilterOSPF false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool FilterPPPoE false'>> /usr/local/vpnserver/vpn_server.config
echo '				uint FloodingSendQueueBufferQuota 33554432'>> /usr/local/vpnserver/vpn_server.config
echo '				bool ManageOnlyLocalUnicastIPv6 true'>> /usr/local/vpnserver/vpn_server.config
echo '				bool ManageOnlyPrivateIP true'>> /usr/local/vpnserver/vpn_server.config
echo '				uint MaxLoggedPacketsPerMinute 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint MaxSession 0'>> /usr/local/vpnserver/vpn_server.config
echo '				bool NoArpPolling false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool NoDhcpPacketLogOutsideHub true'>> /usr/local/vpnserver/vpn_server.config
echo '				bool NoEnum false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool NoIpTable false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool NoIPv4PacketLog false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool NoIPv6AddrPolling false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool NoIPv6DefaultRouterInRAWhenIPv6 true'>> /usr/local/vpnserver/vpn_server.config
echo '				bool NoIPv6PacketLog false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool NoLookBPDUBridgeId false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool NoMacAddressLog true'>> /usr/local/vpnserver/vpn_server.config
echo '				bool NoManageVlanId false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool NoPhysicalIPOnPacketLog false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool NoSpinLockForPacketDelay false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool RemoveDefGwOnDhcpForLocalhost false'>> /usr/local/vpnserver/vpn_server.config
echo '				uint RequiredClientId 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint SecureNAT_MaxDnsSessionsPerIp 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint SecureNAT_MaxIcmpSessionsPerIp 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint SecureNAT_MaxTcpSessionsPerIp 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint SecureNAT_MaxTcpSynSentPerIp 0'>> /usr/local/vpnserver/vpn_server.config
echo '				uint SecureNAT_MaxUdpSessionsPerIp 0'>> /usr/local/vpnserver/vpn_server.config
echo '				bool SecureNAT_RandomizeAssignIp false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool SuppressClientUpdateNotification false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool UseHubNameAsDhcpUserClassOption false'>> /usr/local/vpnserver/vpn_server.config
echo '				bool UseHubNameAsRadiusNasId false'>> /usr/local/vpnserver/vpn_server.config
echo '				string VlanTypeId 0x8100'>> /usr/local/vpnserver/vpn_server.config
echo '				bool YieldAfterStorePacket false'>> /usr/local/vpnserver/vpn_server.config
echo '			}'>> /usr/local/vpnserver/vpn_server.config
echo '			declare SecureNAT'>> /usr/local/vpnserver/vpn_server.config
echo '			{'>> /usr/local/vpnserver/vpn_server.config
echo '				bool Disabled true'>> /usr/local/vpnserver/vpn_server.config
echo '				bool SaveLog true'>> /usr/local/vpnserver/vpn_server.config
echo ''>> /usr/local/vpnserver/vpn_server.config
echo '				declare VirtualDhcpServer'>> /usr/local/vpnserver/vpn_server.config
echo '				{'>> /usr/local/vpnserver/vpn_server.config
echo '					string DhcpDnsServerAddress 192.168.30.1'>> /usr/local/vpnserver/vpn_server.config
echo '					string DhcpDnsServerAddress2 0.0.0.0'>> /usr/local/vpnserver/vpn_server.config
echo '					string DhcpDomainName $'>> /usr/local/vpnserver/vpn_server.config
echo '					bool DhcpEnabled true'>> /usr/local/vpnserver/vpn_server.config
echo '					uint DhcpExpireTimeSpan 7200'>> /usr/local/vpnserver/vpn_server.config
echo '					string DhcpGatewayAddress 192.168.30.1'>> /usr/local/vpnserver/vpn_server.config
echo '					string DhcpLeaseIPEnd 192.168.30.200'>> /usr/local/vpnserver/vpn_server.config
echo '					string DhcpLeaseIPStart 192.168.30.10'>> /usr/local/vpnserver/vpn_server.config
echo '					string DhcpPushRoutes $'>> /usr/local/vpnserver/vpn_server.config
echo '					string DhcpSubnetMask 255.255.255.0'>> /usr/local/vpnserver/vpn_server.config
echo '				}'>> /usr/local/vpnserver/vpn_server.config
echo '				declare VirtualHost'>> /usr/local/vpnserver/vpn_server.config
echo '				{'>> /usr/local/vpnserver/vpn_server.config
echo '					string VirtualHostIp 192.168.30.1'>> /usr/local/vpnserver/vpn_server.config
echo '					string VirtualHostIpSubnetMask 255.255.255.0'>> /usr/local/vpnserver/vpn_server.config
echo '					string VirtualHostMacAddress 5E-0D-3B-49-39-7B'>> /usr/local/vpnserver/vpn_server.config
echo '				}'>> /usr/local/vpnserver/vpn_server.config
echo '				declare VirtualRouter'>> /usr/local/vpnserver/vpn_server.config
echo '				{'>> /usr/local/vpnserver/vpn_server.config
echo '					bool NatEnabled true'>> /usr/local/vpnserver/vpn_server.config
echo '					uint NatMtu 1500'>> /usr/local/vpnserver/vpn_server.config
echo '					uint NatTcpTimeout 1800'>> /usr/local/vpnserver/vpn_server.config
echo '					uint NatUdpTimeout 60'>> /usr/local/vpnserver/vpn_server.config
echo '				}'>> /usr/local/vpnserver/vpn_server.config
echo '			}'>> /usr/local/vpnserver/vpn_server.config
echo '			declare SecurityAccountDatabase'>> /usr/local/vpnserver/vpn_server.config
echo '			{'>> /usr/local/vpnserver/vpn_server.config
echo '				declare CertList'>> /usr/local/vpnserver/vpn_server.config
echo '				{'>> /usr/local/vpnserver/vpn_server.config
echo '				}'>> /usr/local/vpnserver/vpn_server.config
echo '				declare CrlList'>> /usr/local/vpnserver/vpn_server.config
echo '				{'>> /usr/local/vpnserver/vpn_server.config
echo '				}'>> /usr/local/vpnserver/vpn_server.config
echo '				declare GroupList'>> /usr/local/vpnserver/vpn_server.config
echo '				{'>> /usr/local/vpnserver/vpn_server.config
echo '				}'>> /usr/local/vpnserver/vpn_server.config
echo '				declare IPAccessControlList'>> /usr/local/vpnserver/vpn_server.config
echo '				{'>> /usr/local/vpnserver/vpn_server.config
echo '				}'>> /usr/local/vpnserver/vpn_server.config
echo '				declare UserList'>> /usr/local/vpnserver/vpn_server.config
echo '				{'>> /usr/local/vpnserver/vpn_server.config
echo '					declare test'>> /usr/local/vpnserver/vpn_server.config
echo '					{'>> /usr/local/vpnserver/vpn_server.config
echo '						byte AuthNtLmSecureHash CGfMuyzpIC50xHVGA4y+7Q=='>> /usr/local/vpnserver/vpn_server.config
echo '						byte AuthPassword 2HYcRAAci1w/8AxcVZHJ1MPGXKw='>> /usr/local/vpnserver/vpn_server.config
echo '						uint AuthType 1'>> /usr/local/vpnserver/vpn_server.config
echo '						uint64 CreatedTime 1554705703645'>> /usr/local/vpnserver/vpn_server.config
echo '						uint64 ExpireTime 0'>> /usr/local/vpnserver/vpn_server.config
echo '						uint64 LastLoginTime 1554715032217'>> /usr/local/vpnserver/vpn_server.config
echo '						string Note $'>> /usr/local/vpnserver/vpn_server.config
echo '						uint NumLogin 4'>> /usr/local/vpnserver/vpn_server.config
echo '						string RealName $'>> /usr/local/vpnserver/vpn_server.config
echo '						uint64 UpdatedTime 1555041600035'>> /usr/local/vpnserver/vpn_server.config
echo ''>> /usr/local/vpnserver/vpn_server.config
echo '						declare Policy'>> /usr/local/vpnserver/vpn_server.config
echo '						{'>> /usr/local/vpnserver/vpn_server.config
echo '							bool Access true'>> /usr/local/vpnserver/vpn_server.config
echo '							bool ArpDhcpOnly false'>> /usr/local/vpnserver/vpn_server.config
echo '							uint AutoDisconnect 0'>> /usr/local/vpnserver/vpn_server.config
echo '							bool CheckIP false'>> /usr/local/vpnserver/vpn_server.config
echo '							bool CheckIPv6 false'>> /usr/local/vpnserver/vpn_server.config
echo '							bool CheckMac false'>> /usr/local/vpnserver/vpn_server.config
echo '							bool DHCPFilter false'>> /usr/local/vpnserver/vpn_server.config
echo '							bool DHCPForce false'>> /usr/local/vpnserver/vpn_server.config
echo '							bool DHCPNoServer false'>> /usr/local/vpnserver/vpn_server.config
echo '							bool DHCPv6Filter false'>> /usr/local/vpnserver/vpn_server.config
echo '							bool DHCPv6NoServer false'>> /usr/local/vpnserver/vpn_server.config
echo '							bool FilterIPv4 false'>> /usr/local/vpnserver/vpn_server.config
echo '							bool FilterIPv6 false'>> /usr/local/vpnserver/vpn_server.config
echo '							bool FilterNonIP false'>> /usr/local/vpnserver/vpn_server.config
echo '							bool FixPassword false'>> /usr/local/vpnserver/vpn_server.config
echo '							uint MaxConnection 32'>> /usr/local/vpnserver/vpn_server.config
echo '							uint MaxDownload 0'>> /usr/local/vpnserver/vpn_server.config
echo '							uint MaxIP 0'>> /usr/local/vpnserver/vpn_server.config
echo '							uint MaxIPv6 0'>> /usr/local/vpnserver/vpn_server.config
echo '							uint MaxMac 0'>> /usr/local/vpnserver/vpn_server.config
echo '							uint MaxUpload 0'>> /usr/local/vpnserver/vpn_server.config
echo '							bool MonitorPort false'>> /usr/local/vpnserver/vpn_server.config
echo '							uint MultiLogins 0'>> /usr/local/vpnserver/vpn_server.config
echo '							bool NoBridge false'>> /usr/local/vpnserver/vpn_server.config
echo '							bool NoBroadcastLimiter false'>> /usr/local/vpnserver/vpn_server.config
echo '							bool NoIPv6DefaultRouterInRA false'>> /usr/local/vpnserver/vpn_server.config
echo '							bool NoIPv6DefaultRouterInRAWhenIPv6 false'>> /usr/local/vpnserver/vpn_server.config
echo '							bool NoQoS false'>> /usr/local/vpnserver/vpn_server.config
echo '							bool NoRouting false'>> /usr/local/vpnserver/vpn_server.config
echo '							bool NoRoutingV6 false'>> /usr/local/vpnserver/vpn_server.config
echo '							bool NoSavePassword false'>> /usr/local/vpnserver/vpn_server.config
echo '							bool NoServer false'>> /usr/local/vpnserver/vpn_server.config
echo '							bool NoServerV6 false'>> /usr/local/vpnserver/vpn_server.config
echo '							bool PrivacyFilter false'>> /usr/local/vpnserver/vpn_server.config
echo '							bool RAFilter false'>> /usr/local/vpnserver/vpn_server.config
echo '							bool RSandRAFilter false'>> /usr/local/vpnserver/vpn_server.config
echo '							uint TimeOut 20'>> /usr/local/vpnserver/vpn_server.config
echo '							uint VLanId 0'>> /usr/local/vpnserver/vpn_server.config
echo '						}'>> /usr/local/vpnserver/vpn_server.config
echo '						declare Traffic'>> /usr/local/vpnserver/vpn_server.config
echo '						{'>> /usr/local/vpnserver/vpn_server.config
echo '							declare RecvTraffic'>> /usr/local/vpnserver/vpn_server.config
echo '							{'>> /usr/local/vpnserver/vpn_server.config
echo '								uint64 BroadcastBytes 1377514'>> /usr/local/vpnserver/vpn_server.config
echo '								uint64 BroadcastCount 19468'>> /usr/local/vpnserver/vpn_server.config
echo '								uint64 UnicastBytes 1345377'>> /usr/local/vpnserver/vpn_server.config
echo '								uint64 UnicastCount 3172'>> /usr/local/vpnserver/vpn_server.config
echo '							}'>> /usr/local/vpnserver/vpn_server.config
echo '							declare SendTraffic'>> /usr/local/vpnserver/vpn_server.config
echo '							{'>> /usr/local/vpnserver/vpn_server.config
echo '								uint64 BroadcastBytes 54091'>> /usr/local/vpnserver/vpn_server.config
echo '								uint64 BroadcastCount 418'>> /usr/local/vpnserver/vpn_server.config
echo '								uint64 UnicastBytes 277881'>> /usr/local/vpnserver/vpn_server.config
echo '								uint64 UnicastCount 2388'>> /usr/local/vpnserver/vpn_server.config
echo '							}'>> /usr/local/vpnserver/vpn_server.config
echo '						}'>> /usr/local/vpnserver/vpn_server.config
echo '					}'>> /usr/local/vpnserver/vpn_server.config
echo '				}'>> /usr/local/vpnserver/vpn_server.config
echo '			}'>> /usr/local/vpnserver/vpn_server.config
echo '			declare Traffic'>> /usr/local/vpnserver/vpn_server.config
echo '			{'>> /usr/local/vpnserver/vpn_server.config
echo '				declare RecvTraffic'>> /usr/local/vpnserver/vpn_server.config
echo '				{'>> /usr/local/vpnserver/vpn_server.config
echo '					uint64 BroadcastBytes 11338463'>> /usr/local/vpnserver/vpn_server.config
echo '					uint64 BroadcastCount 156886'>> /usr/local/vpnserver/vpn_server.config
echo '					uint64 UnicastBytes 82781105'>> /usr/local/vpnserver/vpn_server.config
echo '					uint64 UnicastCount 960702'>> /usr/local/vpnserver/vpn_server.config
echo '				}'>> /usr/local/vpnserver/vpn_server.config
echo '				declare SendTraffic'>> /usr/local/vpnserver/vpn_server.config
echo '				{'>> /usr/local/vpnserver/vpn_server.config
echo '					uint64 BroadcastBytes 12369231'>> /usr/local/vpnserver/vpn_server.config
echo '					uint64 BroadcastCount 171224'>> /usr/local/vpnserver/vpn_server.config
echo '					uint64 UnicastBytes 31309285'>> /usr/local/vpnserver/vpn_server.config
echo '					uint64 UnicastCount 355764'>> /usr/local/vpnserver/vpn_server.config
echo '				}'>> /usr/local/vpnserver/vpn_server.config
echo '			}'>> /usr/local/vpnserver/vpn_server.config
echo '		}'>> /usr/local/vpnserver/vpn_server.config
echo '	}'>> /usr/local/vpnserver/vpn_server.config
echo '	declare VirtualLayer3SwitchList'>> /usr/local/vpnserver/vpn_server.config
echo '	{'>> /usr/local/vpnserver/vpn_server.config
echo '	}'>> /usr/local/vpnserver/vpn_server.config
echo '}'>> /usr/local/vpnserver/vpn_server.config



#Generate random MAC for softether Tap Adapter vpn_server.config
export MAC=$(printf '%.2x\n' "$(shuf -i 0-281474976710655 -n 1)" | sed -r 's/(..)/\1:/g' | cut -d: -f -6 |  tr '[:lower:]' '[:upper:]')
echo $MAC

#change the default mac for TAP adapter in the config to a random one
sed -i "s/5E-BD-34-92-20-30/$MAC/g" /usr/local/vpnserver/vpn_server.config

#Create systemd init file for Softether VPN service
touch /lib/systemd/system/vpnserver.service

echo '[Unit]'>> /lib/systemd/system/vpnserver.service
echo 'Description=SoftEther VPN Server'>> /lib/systemd/system/vpnserver.service
echo 'After=network.target'>> /lib/systemd/system/vpnserver.service
echo ''>> /lib/systemd/system/vpnserver.service
echo ''>> /lib/systemd/system/vpnserver.service
echo ''>> /lib/systemd/system/vpnserver.service
echo '[Service]'>> /lib/systemd/system/vpnserver.service
echo 'Type=forking'>> /lib/systemd/system/vpnserver.service
echo 'ExecStart=/usr/local/vpnserver/vpnserver start'>> /lib/systemd/system/vpnserver.service
echo 'ExecStop=/usr/local/vpnserver/vpnserver stop'>> /lib/systemd/system/vpnserver.service
echo 'ExecStartPost=/bin/sleep 05'>> /lib/systemd/system/vpnserver.service
echo 'ExecStartPost=/bin/sh /root/softether-iptables.sh'>> /lib/systemd/system/vpnserver.service
echo 'ExecStartPost=/bin/sleep 03'>> /lib/systemd/system/vpnserver.service
echo 'ExecStartPost=/bin/systemctl start dnsmasq.service'>> /lib/systemd/system/vpnserver.service
echo 'ExecReload=/bin/sleep 05'>> /lib/systemd/system/vpnserver.service
echo 'ExecReload=/bin/sh /root/softether-iptables.sh'>> /lib/systemd/system/vpnserver.service
echo 'ExecReload=/bin/sleep 03'>> /lib/systemd/system/vpnserver.service
echo 'ExecReload=/bin/systemctl restart dnsmasq.service'>> /lib/systemd/system/vpnserver.service
echo 'ExecStopPost=/bin/systemctl stop dnsmasq.service'>> /lib/systemd/system/vpnserver.service
echo 'Restart=always'>> /lib/systemd/system/vpnserver.service
echo ''>> /lib/systemd/system/vpnserver.service
echo '[Install]'>> /lib/systemd/system/vpnserver.service
echo 'WantedBy=multi-user.target'>> /lib/systemd/system/vpnserver.service



#Create DNSMasq conf

touch /etc/dnsmasq.conf
echo '################################################################################## Interface Settings'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '# Listen to interface'>> /etc/dnsmasq.conf
echo '# In this case it is the Softether bridge'>> /etc/dnsmasq.conf
echo 'interface=tap_soft'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '# Dont ever listen to anything on eth0, you wouldnt want that.'>> /etc/dnsmasq.conf
echo 'except-interface=ens18'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '# In case you have bind on your server and doesnt want dnsmasq to use the default dns port #53:'>> /etc/dnsmasq.conf
echo '# port=5353'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo 'listen-address=192.168.30.1'>> /etc/dnsmasq.conf
echo 'bind-interfaces'>> /etc/dnsmasq.conf
echo '################################################################################## Options'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '# Lets give the connecting clients an internal IP'>> /etc/dnsmasq.conf
echo 'dhcp-range=tap_soft,192.168.30.10,192.168.30.200,720h'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '# Default route and dns'>> /etc/dnsmasq.conf
echo 'dhcp-option=tap_soft,3,192.168.30.1'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '# enable dhcp'>> /etc/dnsmasq.conf
echo 'dhcp-authoritative'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '# enable IPv6 Route Advertisements'>> /etc/dnsmasq.conf
echo 'enable-ra'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '#  have your simple hosts expanded to domain'>> /etc/dnsmasq.conf
echo 'expand-hosts'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '# Let dnsmasq use the dns servers in the order you chose.'>> /etc/dnsmasq.conf
echo 'strict-order'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '# Lets try not giving the same IP to all, right?'>> /etc/dnsmasq.conf
echo 'dhcp-no-override'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '# Lets assign a unique and real IPv6 address to all clients.'>> /etc/dnsmasq.conf
echo '# Here, we are using the IPv6 addresses from the he-ipv6 interface (Hurricane Electric ipv6 tunnel)'>> /etc/dnsmasq.conf
echo '# You should replace it with your own IP range.'>> /etc/dnsmasq.conf
echo '# This way even if you have only 1 shared IPv4'>> /etc/dnsmasq.conf
echo '# All of your clients can have a real and unique IPv6 address.'>> /etc/dnsmasq.conf
echo '# you can try slaac,ra-only | slaac,ra-names | slaac,ra-stateless in case you have trouble connecting'>> /etc/dnsmasq.conf
echo '#dhcp-range=tap_soft,2001:0470:1f15:0000:0000:0000:0001,2A00:1CA8:2A:8:FFFF:FFFF:FFFF:FFFF,ra-advrouter,slaac,64,infinite'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '# For tunnelbroker, assign your 1f14 ip address to the tunnel interface and use 1f15 routable addresses in softether and dnsmasq'>> /etc/dnsmasq.conf
echo '#dhcp-range=tap_soft,2001:0470:1f15:XXXX:0000:0000:000:0011,2001:0470:1f15:XXXX:0000:0000:0000:ffff,slaac,ra-stateless,64,2d'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '# Lets advertise ourself as a DNSSec server.'>> /etc/dnsmasq.conf
echo '# Since were running in the VPN network this shouldnt be any problem.'>> /etc/dnsmasq.conf
echo '# Copy the DNSSEC Authenticated Data bit from upstream servers to downstream clients and cache it.'>> /etc/dnsmasq.conf
echo '# This is an alternative to having dnsmasq validate DNSSEC, but it depends on the security of the network'>> /etc/dnsmasq.conf
echo '# between dnsmasq and the upstream servers, and the trustworthiness of the upstream servers.'>> /etc/dnsmasq.conf
echo '#proxy-dnssec'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '# The following directives prevent dnsmasq from forwarding plain names (without any dots)'>> /etc/dnsmasq.conf
echo '# or addresses in the non-routed address space to the parent nameservers.'>> /etc/dnsmasq.conf
echo 'domain-needed'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '# Never forward addresses in the non-routed address spaces'>> /etc/dnsmasq.conf
echo 'bogus-priv'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '# blocks probe-machines attack'>> /etc/dnsmasq.conf
echo 'stop-dns-rebind'>> /etc/dnsmasq.conf
echo 'rebind-localhost-ok'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '# Set the maximum number of concurrent DNS queries. The default value is 150. Adjust to your needs.'>> /etc/dnsmasq.conf
echo 'dns-forward-max=300'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '# stops dnsmasq from getting DNS server addresses from /etc/resolv.conf'>> /etc/dnsmasq.conf
echo '# but from below'>> /etc/dnsmasq.conf
echo 'no-resolv'>> /etc/dnsmasq.conf
echo 'no-poll'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '# Prevent Windows 7 DHCPDISCOVER floods'>> /etc/dnsmasq.conf
echo '# http://brielle.sosdg.org/archives/522-Windows-7-flooding-DHCP-server-with-DHCPINFORM-messages.html'>> /etc/dnsmasq.conf
echo 'dhcp-option=252,"\n"'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '################################################################################## External DNS Servers'>> /etc/dnsmasq.conf
echo '# Use this DNS servers for incoming DNS requests'>> /etc/dnsmasq.conf
echo 'server=208.67.222.222'>> /etc/dnsmasq.conf
echo 'server=208.67.220.220'>> /etc/dnsmasq.conf
echo 'server=8.8.4.4'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '# Use these IPv6 DNS Servers for lookups/ Google and OpenDNS'>> /etc/dnsmasq.conf
echo 'server=2620:0:ccd::2'>> /etc/dnsmasq.conf
echo 'server=2001:4860:4860::8888'>> /etc/dnsmasq.conf
echo 'server=2001:4860:4860::8844'>> /etc/dnsmasq.conf
echo '#########################################'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '################################################################################## Client DNS Servers'>> /etc/dnsmasq.conf
echo '# Lets send these DNS Servers to clients.'>> /etc/dnsmasq.conf
echo '# The first IP is the IPv4 and IPv6 addresses that are already assigned to the tap_soft'>> /etc/dnsmasq.conf
echo '# So that everything runs through us.'>> /etc/dnsmasq.conf
echo '# This is good for caching and adblocking.'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '# Set IPv4 DNS server for client machines # option:6'>> /etc/dnsmasq.conf
echo 'dhcp-option=option:dns-server,192.168.30.1,176.103.130.130'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '# Set IPv6 DNS server for clients'>> /etc/dnsmasq.conf
echo '# You can change the first IP with the ipv6 address of your tap_soft if you '>> /etc/dnsmasq.conf
echo '# want all dns queries to go through your server...'>> /etc/dnsmasq.conf
echo 'dhcp-option=option6:dns-server,[2a00:5a60::ad2:0ff],[2a00:5a60::ad1:0ff]'>> /etc/dnsmasq.conf
echo '#########################################'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '######################################### TTL & Caching options'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '# How many DNS queries should we cache? By defaults this is 150'>> /etc/dnsmasq.conf
echo '# Can go up to 10k.'>> /etc/dnsmasq.conf
echo 'cache-size=10000'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '# Negative caching allows dnsmasq to remember 'no such domain' answers from the parent nameservers,'>> /etc/dnsmasq.conf
echo '# so it does not query for the same non-existent hostnames again and again.'>> /etc/dnsmasq.conf
echo '# This is probably useful for spam filters or MTA services.'>> /etc/dnsmasq.conf
echo '#no-negcache'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '# The neg-ttl directive sets a default TTL value to add to negative replies from the parent nameservers,'>> /etc/dnsmasq.conf
echo '# in case these replies do not contain TTL information.'>> /etc/dnsmasq.conf
echo '# If neg-ttl is not set and a negative reply from a parent DNS server does not contain TTL information,'>> /etc/dnsmasq.conf
echo '# then dnsmasq will not cache the reply.'>> /etc/dnsmasq.conf
echo 'neg-ttl=80000'>> /etc/dnsmasq.conf
echo 'local-ttl=3600'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '# TTL'>> /etc/dnsmasq.conf
echo 'dhcp-option=23,64'>> /etc/dnsmasq.conf
echo '#########################################'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '################################################################################## MISC'>> /etc/dnsmasq.conf
echo '# Send microsoft-specific option to tell windows to release the DHCP lease'>> /etc/dnsmasq.conf
echo '# when it shuts down. Note the "i" flag, to tell dnsmasq to send the'>> /etc/dnsmasq.conf
echo '# value as a four-byte integer - thats what microsoft wants. See'>> /etc/dnsmasq.conf
echo 'dhcp-option=vendor:MSFT,2,1i'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '#########################################'>> /etc/dnsmasq.conf
echo '## 44-47 NetBIOS'>> /etc/dnsmasq.conf
echo 'dhcp-option=44,192.168.30.1 # set netbios-over-TCP/IP nameserver(s) aka WINS server(s)'>> /etc/dnsmasq.conf
echo 'dhcp-option=45,192.168.30.1 # netbios datagram distribution server'>> /etc/dnsmasq.conf
echo 'dhcp-option=46,8         # netbios node type'>> /etc/dnsmasq.conf
echo 'dhcp-option=47'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '# IF you want to give clients the same static internal IP,'>> /etc/dnsmasq.conf
echo '# you should create and use use /etc/ethers for static hosts;'>> /etc/dnsmasq.conf
echo '# same format as --dhcp-host'>> /etc/dnsmasq.conf
echo '# <hwaddr> [<hostname>] <ipaddr>'>> /etc/dnsmasq.conf
echo 'read-ethers'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '# Additional hosts, for adblocking.'>> /etc/dnsmasq.conf
echo '# You can create that file yourself or just download and run:'>> /etc/dnsmasq.conf
echo '# https://github.com/nomadturk/vpn-adblock/blob/master/updateHosts.sh'>> /etc/dnsmasq.conf
echo 'addn-hosts=/etc/hosts.supp'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo 'log-facility=/var/log/dnsmasq.log'>> /etc/dnsmasq.conf
echo 'log-async=5'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '################################################################################## Experimental'>> /etc/dnsmasq.conf
echo 'log-dhcp'>> /etc/dnsmasq.conf
echo 'quiet-dhcp6'>> /etc/dnsmasq.conf
echo '#dhcp-option=option:router,192.168.30.1'>> /etc/dnsmasq.conf
echo '#dhcp-option=option:ntp-server,192.168.30.1'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo '# With settings below, you can ping other clients on your lan.'>> /etc/dnsmasq.conf
echo '#dhcp-option=option:domain-search,lan'>> /etc/dnsmasq.conf
echo '#dhcp-option=option6:domain-search,lan'>> /etc/dnsmasq.conf
echo '#domain=YOURDOMAINHERE'>> /etc/dnsmasq.conf
echo '# Gateway'>> /etc/dnsmasq.conf
echo 'dhcp-option=3,192.168.30.1'>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf
echo ''>> /etc/dnsmasq.conf


shopt -s extglob; NET_INTERFACE=$(ip link | awk -F: '$0 !~ "lo|vir|wl|tap_soft|^[^0-9]"{print $2;getline}'); NET_INTERFACE="${NET_INTERFACE##*( )}"; sed -i s/ens3/"$NET_INTERFACE"/g /etc/dnsmasq.conf; shopt -u extglob;

#ad blocking hosts
wget -O /root/updateHosts.sh https://raw.githubusercontent.com/nomadturk/vpn-adblock/master/updateHosts.sh; chmod a+x /root/updateHosts.sh && bash /root/updateHosts.sh;

#Install adblocking cron.
command="/root/updateHosts.sh >/dev/null 2>&1"
job="0 0 * * * $command"
cat <(fgrep -i -v "$command" <(crontab -l)) <(echo "$job") | crontab -


#Install Log purging.
command2="find /usr/local/vpnserver/ -name '*.log' -delete; > /var/log/dnsmasq.log; >/dev/null 2>&1"
job2="* * * * * $command2"
cat <(fgrep -i -v "$command2" <(crontab -l)) <(echo "$job2") | crontab -


#Ipv4 enabling and execute it
echo 'net.core.somaxconn=4096' >> /etc/sysctl.conf
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
echo 'net.ipv4.conf.all.send_redirects = 0' >> /etc/sysctl.conf
echo 'net.ipv4.conf.all.accept_redirects = 1' >> /etc/sysctl.conf
echo 'net.ipv4.conf.all.rp_filter = 1' >> /etc/sysctl.conf
echo 'net.ipv4.conf.default.send_redirects = 1' >> /etc/sysctl.conf
echo 'net.ipv4.conf.default.proxy_arp = 0' >> /etc/sysctl.conf
sysctl -f


#Grab base Sofether Iptables rules

touch /root/softether-iptables.sh; chmod a+x /root/softether-iptables.sh;
echo '#!/bin/sh'>> /root/softether-iptables.sh
echo '##########################################################################################################################################'>> /root/softether-iptables.sh
echo '### Configuration'>> /root/softether-iptables.sh
echo '#############################'>> /root/softether-iptables.sh
echo ''>> /root/softether-iptables.sh
echo '#DAEMON=/usr/local/vpnserver/vpnserver           # Change this only if you have installed the vpnserver to an alternate location.'>> /root/softether-iptables.sh
echo '#LOCK=/var/lock/vpnserver                        # No need to edit this.'>> /root/softether-iptables.sh
echo 'TAP_ADDR=192.168.30.1                              # Main IP of your TAP interface'>> /root/softether-iptables.sh
echo 'TAP_INTERFACE=tap_soft                     # The name of your TAP interface.'>> /root/softether-iptables.sh
echo 'VPN_SUBNET=192.168.30.0/24                         # Virtual IP subnet you want to use within your VPN'>> /root/softether-iptables.sh
echo '#NET_INTERFACE=ens3                              # Your network adapter that connects you to the world.In OpenVZ this is venet0 for example.'>> /root/softether-iptables.sh
echo 'shopt -s extglob; NET_INTERFACE=$(ip link | awk -F: '$0 !~ "lo|vir|wl|tap_soft|^[^0-9]"{print $2;getline}'); NET_INTERFACE="${NET_INTERFACE##*( )}"; shopt -u extglob;'>> /root/softether-iptables.sh
echo '#IPV6_ADDR=2t00:1ba7:001b:0007:0000:0000:0000:0001      # You can also assign this as DNS server in dnsmasq config.'>> /root/softether-iptables.sh
echo '#IPV6_SUBNET=2t00:1ba7:1b:7::/64               # Used to assign IPv6 to connecting clients. Remember to use the same subnet in dnsmasq.conf'>> /root/softether-iptables.sh
echo '#YOUREXTERNALIP=1.2.3.4                  # Your machines external IPv4 address. '>> /root/softether-iptables.sh
echo "YOUREXTERNALIP=$(hostname -I | cut -d ' ' -f 1)                                                # Write down you IP or one of the IP adresses if you have more than one.">> /root/softether-iptables.sh
echo '                                                # Warning! NAT Machine users, here write the local IP address of your VPS instead of the external IP.'>> /root/softether-iptables.sh
echo ''>> /root/softether-iptables.sh
echo '#############################'>> /root/softether-iptables.sh
echo '### End of Configuration'>> /root/softether-iptables.sh
echo '##########################################################################################################################################'>> /root/softether-iptables.sh
echo ''>> /root/softether-iptables.sh
echo '#Flush Current rules'>> /root/softether-iptables.sh
echo 'iptables -F && iptables -X'>> /root/softether-iptables.sh
echo '#######################################################################################'>> /root/softether-iptables.sh
echo '#	Rules for IPTables. You can remove and use these iptables-persistent if you want '>> /root/softether-iptables.sh
echo '#######################################################################################'>> /root/softether-iptables.sh
echo '# Assign $TAP_ADDR to our tap interface'>> /root/softether-iptables.sh
echo '/sbin/ifconfig $TAP_INTERFACE $TAP_ADDR'>> /root/softether-iptables.sh
echo '#'>> /root/softether-iptables.sh
echo '# Forward all VPN traffic that comes from VPN_SUBNET through $NET_INTERFACE interface for outgoing packets.'>> /root/softether-iptables.sh
echo 'iptables -t nat -A POSTROUTING -s $VPN_SUBNET -j SNAT --to-source $YOUREXTERNALIP'>> /root/softether-iptables.sh
echo '# Alternate rule if your server has dynamic IP'>> /root/softether-iptables.sh
echo '#iptables -t nat -A POSTROUTING -s $VPN_SUBNET -o $NET_INTERFACE -j MASQUERADE'>> /root/softether-iptables.sh
echo '#'>> /root/softether-iptables.sh
echo '# Allow VPN Interface to access the whole world, back and forth.'>> /root/softether-iptables.sh
echo 'iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT'>> /root/softether-iptables.sh
echo 'iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT'>> /root/softether-iptables.sh
echo 'iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT'>> /root/softether-iptables.sh
echo '# '>> /root/softether-iptables.sh
echo 'iptables -A INPUT -s $VPN_SUBNET -m state --state NEW -j ACCEPT '>> /root/softether-iptables.sh
echo 'iptables -A OUTPUT -s $VPN_SUBNET -m state --state NEW -j ACCEPT '>> /root/softether-iptables.sh
echo 'iptables -A FORWARD -s $VPN_SUBNET -m state --state NEW -j ACCEPT '>> /root/softether-iptables.sh
echo '# '>> /root/softether-iptables.sh
echo '# IPv6'>> /root/softether-iptables.sh
echo '# This is the IP we use to reply DNS requests.'>> /root/softether-iptables.sh
echo '#ifconfig $TAP_INTERFACE inet6 add $IPV6_ADDR'>> /root/softether-iptables.sh
echo '#'>> /root/softether-iptables.sh
echo '# Without assigning the whole /64 subnet, Softether doesnt give connecting clients IPv6 addresses.'>> /root/softether-iptables.sh
echo '#ifconfig $TAP_INTERFACE inet6 add $IPV6_SUBNET'>> /root/softether-iptables.sh
echo '#'>> /root/softether-iptables.sh
echo '# Lets define forwarding rules for IPv6 as well...'>> /root/softether-iptables.sh
echo '#ip6tables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT'>> /root/softether-iptables.sh
echo '#ip6tables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT'>> /root/softether-iptables.sh
echo '#ip6tables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT'>> /root/softether-iptables.sh
echo '#ip6tables -A FORWARD -j ACCEPT'>> /root/softether-iptables.sh
echo '#ip6tables -A INPUT -j ACCEPT'>> /root/softether-iptables.sh
echo '#ip6tables -A OUTPUT -j ACCEPT'>> /root/softether-iptables.sh
echo ''>> /root/softether-iptables.sh
echo '# You can enable this for kernels 3.13 and up'>> /root/softether-iptables.sh
echo '#ip6tables -t nat -A POSTROUTING -o tap_soft -j MASQUERADE'>> /root/softether-iptables.sh
echo '#######################################################################################'>> /root/softether-iptables.sh
echo '#	End of IPTables Rules'>> /root/softether-iptables.sh
echo '#######################################################################################'>> /root/softether-iptables.sh
echo ''>> /root/softether-iptables.sh



#Make ethers file for dnsmasq to do static assignments based on Mac Addresses
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
echo "To manage the server via Windows Server GUI grab the Server Manager client from https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/releases/download/v4.30-9696-beta/softether-vpnserver_vpnbridge-v4.30-9696-beta-2019.07.08-windows-x86_x64-intel.exe"
VPNEXTERNALIP=$(hostname -I | cut -d ' ' -f 1)
echo "Connect to $VPNEXTERNALIP:443"
echo "To connect to the VPN grab and install the softether vpn client from: http://www.softether-download.com/en.aspx?product=softether"
echo "Complete"