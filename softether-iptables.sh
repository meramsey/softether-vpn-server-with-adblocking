#!/bin/bash
##########################################################################################################################################
### Configuration
#############################
#
#DAEMON=/usr/local/vpnserver/vpnserver           # Change this only if you have installed the vpnserver to an alternate location.
#LOCK=/var/lock/vpnserver                        # No need to edit this.
TAP_ADDR=192.168.30.1                              # Main IP of your TAP interface
TAP_INTERFACE=tap_soft                     # The name of your TAP interface.
VPN_SUBNET=192.168.30.0/24                         # Virtual IP subnet you want to use within your VPN

#Harcoded option
#NET_INTERFACE=ens3                              # Your network adapter that connects you to the world.In OpenVZ this is venet0 for example.

#dynamically detect NET_INTERFACE
NET_INTERFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)

#VPNEXTERNALIP=1.2.3.4                  # Your machines external IPv4 address. 
VPNEXTERNALIP=$(wget -qO- -t1 -T2 ipv4.icanhazip.com) # Write down you IP or one of the IP adresses if you have more than one.
                                                # Warning! NAT Machine users, here write the local IP address of your VPS instead of the external IP.
#Harcoded option
#IPV6_ADDR=#IPV6_ADDR=2t00:1ba7:001b:0007:0000:0000:0000:0001      # You can also assign this as DNS server in dnsmasq config.
#IPV6_SUBNET=2t00:1ba7:1b:7::/64               # Used to assign IPv6 to connecting clients. Remember to use the same subnet in dnsmasq.conf

#dynamically detect Ipv6
#IPV6_ADDR=$(dig -6 @resolver1.opendns.com -t any myip.opendns.com +short); #echo $IPV6_ADDR;
IPV6_ADDR=$(wget -qO- -t1 -T2 ipv6.icanhazip.com)
IPV6_SUBNET=$(/sbin/ip addr | grep 'state UP' -A4 | grep inet6 | awk '{print $2}'| grep -v 'fe80'); #echo $IPV6_SUBNET;

#############################
### End of Configuration
##########################################################################################################################################

#Flush Current rules
iptables -F && iptables -X && iptables -t nat -F
ip6tables -F && ip6tables -X && ip6tables -t nat -F
#######################################################################################
# Base SoftEther VPN Rules for IPTables. You can remove and use these iptables-persistent if you want 
#######################################################################################
# Assign $TAP_ADDR to our tap interface
/sbin/ifconfig $TAP_INTERFACE $TAP_ADDR
#
# Forward all VPN traffic that comes from VPN_SUBNET through $NET_INTERFACE interface for outgoing packets.
iptables -t nat -A POSTROUTING -s $VPN_SUBNET -j SNAT --to-source $VPNEXTERNALIP
# Alternate rule if your server has dynamic IP
#iptables -t nat -A POSTROUTING -s $VPN_SUBNET -o $NET_INTERFACE -j MASQUERADE
#
# Allow VPN Interface to access the whole world, back and forth.
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
# 
iptables -A INPUT -s $VPN_SUBNET -m state --state NEW -j ACCEPT 
iptables -A OUTPUT -s $VPN_SUBNET -m state --state NEW -j ACCEPT 
iptables -A FORWARD -s $VPN_SUBNET -m state --state NEW -j ACCEPT 
# 
# IPv6
# This is the IP we use to reply DNS requests.
ifconfig $TAP_INTERFACE inet6 add $IPV6_ADDR
#
# Without assigning the whole /64 subnet, Softether doesn't give connecting clients IPv6 addresses.
ifconfig $TAP_INTERFACE inet6 add $IPV6_SUBNET
#
# Let's define forwarding rules for IPv6 as well...
ip6tables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
ip6tables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
ip6tables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
ip6tables -A FORWARD -j ACCEPT
ip6tables -A INPUT -j ACCEPT
ip6tables -A OUTPUT -j ACCEPT

# You can enable this for kernels 3.13 and up
ip6tables -t nat -A POSTROUTING -o tap_soft -j MASQUERADE
#######################################################################################
#	End of Base IPTables Rules
#######################################################################################

# Source Client IP portforwarding rules
source /root/client_ports_iptables_conf.sh

# Source Wireguard IP iptables rule if exists
FILE="/root/softwire/wireguard_iptables_up.sh"     
if [ -f $FILE ]; then
   source /root/softwire/wireguard_iptables_up.sh
fi