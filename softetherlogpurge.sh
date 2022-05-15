#!/usr/bin/env bash
# as root use "nano /root/softetherlogpurge.sh" to create file and save the contents of this into it
# then execute "chmod +x /root/softetherlogpurge.sh" to make it executable
# "crontab -e" to add the line "* * * * * /root/softetherlogpurge.sh >/dev/null 2>&1" to setup all .logs for SofEther to be purged every minute.

# Script to Purge SoftEther Log
# Copyleft (C) 2018 WhatTheServer - All Rights Reserved
# Permission to copy and modify is granted under the CopyLeft license
# Last revised 2022-05-14

# Update: debian apt packages write logs to new location
# https://launchpad.net/ubuntu/+source/softether-vpn
# /var/log/softether/server_log/vpn_20220515.log
# /var/log/softether/security_log/DEFAULT/sec_20220515.log

#Ensure packet logs are cleared if they ever get enabled
truncate -s 0 /usr/local/vpnserver/packet_log/**/*.log >/dev/null 2>&1
truncate -s 0 /var/log/softether/packet_log/**/*.log >/dev/null 2>&1

#Ensure security logs are cleared if they ever get enabled
truncate -s 0 /usr/local/vpnserver/security_log/**/*.log >/dev/null 2>&1
truncate -s 0 /var/log/softether/security_log/**/*.log >/dev/null 2>&1

#Ensure softether server logs are cleared if they ever get enabled
truncate -s 0 /usr/local/vpnserver/server_log/*.log >/dev/null 2>&1
truncate -s 0 /var/log/softether/server_log/*.log >/dev/null 2>&1

#Delete softether empty log file names
find /usr/local/vpnserver/ -name '*.log' -delete >/dev/null 2>&1
find /var/log/softether -name '*.log' -delete >/dev/null 2>&1

#Delete dnsmasq dhcp log
> /var/log/dnsmasq.log >/dev/null 2>&1

# Alternatively could do this
# rm -rf /var/log/softether/ ; ln -s /dev/null /var/log/softether

# once off
# unlink /var/log/dnsmasq.log ; ln -s /dev/null /var/log/dnsmasq.log
