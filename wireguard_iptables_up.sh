#!/bin/bash
#Wireguard Iptables up
#nano /root/softwire/wireguard_iptables_up.sh

EXT_NET_IF=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
#===============================
#dns_resolvers Adguard
dns_resolver1=176.103.130.130
dns_resolver2=176.103.130.131

dns_resolverv61=2a00:5a60::ad1:0ff
dns_resolverv62=2a00:5a60::ad2:0ff
#===============================


iptables -t mangle -A POSTROUTING -p tcp --tcp-flags SYN,RST SYN -o $EXT_NET_IF -j TCPMSS --clamp-mss-to-pmtu
ip6tables -t mangle -A POSTROUTING -p tcp --tcp-flags SYN,RST SYN -o $EXT_NET_IF -j TCPMSS --clamp-mss-to-pmtu
iptables -t nat -A POSTROUTING -o $EXT_NET_IF -j MASQUERADE
ip6tables -t nat -A POSTROUTING -o $EXT_NET_IF -j MASQUERADE
iptables -A FORWARD -i %i -j ACCEPT
ip6tables -A FORWARD -i %i -j ACCEPT

#Drop connections between peers for privacy
iptables -I FORWARD --src 10.127.0.0/24 --dst 10.127.0.0/24 -j DROP

#ensure no DNS leaks
iptables -t nat -A PREROUTING -i %i -p udp -m udp --dport 53 -j DNAT --to-destination $dns_resolver1:53
iptables -t nat -A PREROUTING -i %i -p tcp -m tcp --dport 53 -j DNAT --to-destination $dns_resolver1:53
iptables -t nat -A PREROUTING -i %i -p udp -m udp --dport 53 -j DNAT --to-destination $dns_resolver2:53
iptables -t nat -A PREROUTING -i %i -p tcp -m tcp --dport 53 -j DNAT --to-destination $dns_resolver2:53
ip6tables -t nat -A PREROUTING -i %i -p udp -m udp --dport 53 -j DNAT --to-destination $dns_resolverv61:53
ip6tables -t nat -A PREROUTING -i %i -p tcp -m tcp --dport 53 -j DNAT --to-destination $dns_resolverv61:53
ip6tables -t nat -A PREROUTING -i %i -p udp -m udp --dport 53 -j DNAT --to-destination $dns_resolverv62:53
ip6tables -t nat -A PREROUTING -i %i -p tcp -m tcp --dport 53 -j DNAT --to-destination $dns_resolverv62:53
