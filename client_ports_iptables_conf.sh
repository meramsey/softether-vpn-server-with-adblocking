#!/bin/bash

YOUREXTERNALIP=$(wget -qO- -t1 -T2 ipv4.icanhazip.com)

#Example "1.2.3.4" is VPN node IP. Client name is "username" MacAddress is "ae:e7:8a:9a:22:34" Port to forward is "1434". Client's static internal IP "192.168.30.2"

#username ae:e7:8a:9a:22:34 192.168.30.2 port 1434
iptables -t nat -A PREROUTING -d $YOUREXTERNALIP -p tcp --dport 1434 -j DNAT --to-dest 192.168.30.2:1434 -m comment --comment 'username'
iptables -t nat -A PREROUTING -d $YOUREXTERNALIP -p udp --dport 1434 -j DNAT --to-dest 192.168.30.2:1434 -m comment --comment 'username'
iptables -t filter -A INPUT -p tcp -d 192.168.30.2 --dport 1434 -j ACCEPT -m comment --comment 'username'
iptables -t filter -A INPUT -p udp -d 192.168.30.2 --dport 1434 -j ACCEPT -m comment --comment 'username'

