#!/usr/bin/env bash

# touch ${HOME}/softhervpn-hub-creds.sh
# chmod +x ${HOME}/softhervpn-hub-creds.sh

####### Begin Config ########
# adminhub . The HUB in which we will operate by default. I have put VPN, but it will be the one you have in your configuration
HUBNAME="VPN"
# PASSWORD . The HUB administrator password.
ADMIN_HUB_PASSWORD="differentadminpass"
# Hostname for the SSL for softethervpn if not set at OS level level.
VPN_HOSTNAME=""
####### Begin Config ########

# Export variables so they can be sourced in cron script
export HUBNAME
export ADMIN_HUB_PASSWORD
export VPN_HOSTNAME