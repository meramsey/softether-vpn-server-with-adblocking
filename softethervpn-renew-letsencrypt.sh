#!/usr/bin/env bash
# SoftetherVPN Let's Encrypt renewal post-hook or cron-script
# Source Reference: https://calnus.com/2017/07/09/autorenovacion-de-certificado-de-softether-vpn-con-lets-encrypt/
# touch ${HOME}/softethervpn-renew-letsencrypt.sh
# chmod +x ${HOME}/softethervpn-renew-letsencrypt.sh
# Setting a cron Weekly: https://crontab.guru/#5_1_*_*_0
# Crontab to set via `crontab -l`
# 5 1 * * 0 bash ${HOME}/softethervpn-renew-letsencrypt.sh

####### Begin Config ########
# adminhub . The HUB in which we will operate by default. I have put AZURE, but it will be the one you have in your configuration
HUBNAME="AZURE"
# PASSWORD . The HUB administrator password.
ADMIN_HUB_PASSWORD="passworddeadministrador"
# Hostname for the SSL for softethervpn
VPN_HOSTNAME="vpn.calnus.com"

# recommended to use config file and source it defining the path below will allow it to be sourced instead if it exists
CONFIG_FILENAME="${HOME}/softhervpn-hub-creds.sh"
####### Begin Config ########

echo
# Below loads the config if it exists which will overwrite the variables above so the script can be reused and the config sourced for credentials.
if [ -f "${CONFIG_FILENAME}" ]
then
    if [ -s "${CONFIG_FILENAME}" ]
    then
        echo "Config File: ${CONFIG_FILENAME} exists and not empty. Sourcing now..."
		source "${CONFIG_FILENAME}"
    else
 echo "Config File: ${CONFIG_FILENAME} exists but empty. Skipping sourcing"
    fi
else
    echo "Config File: ${CONFIG_FILENAME} not exists. Skipping sourcing"
fi

echo

# If VPN_HOSTNAME is not set from script or config lets use hostname then as a fallback if it resolves.
if [[ -z "$VPN_HOSTNAME" ]]; then
	# Get hostname from host
	HostName=$(hostname --fqdn)
	# If hostname resolves externally use this by default for the VPN_HOSTNAME
	if [ -n "$(dig @1.1.1.1 +short "${HostName}")" ]; then
		echo "${HostName} resolves to a valid IP"
		VPN_HOSTNAME=$HostName
	fi
fi


# Renew certificate directly via script
# certbot renew --quiet

# Alternatively you could call the script as post hook in a cron if thats more to your liking
# 5 1 * * 0 certbot renew --quiet --deploy-hook ${HOME}/softethervpn-renew-letsencrypt.sh


# Uncomment the below to see command echo'd vs executed to confirm it looks as expected before run
#echo ; echo "Command that would been run: "; echo "/usr/local/vpnserver/vpncmd /server localhost /adminhub:"${HUBNAME}" /PASSWORD:"${ADMIN_HUB_PASSWORD}" /CMD ServerCertSet /LOADKEY:/etc/letsencrypt/live/"${VPN_HOSTNAME}"/privkey.pem /LOADCERT:/etc/letsencrypt/live/"${VPN_HOSTNAME}"/cert.pem"


echo "Checking SoftherVPN ServerInformation with provided password via DEFAULT value"
softethervpn_auth_check=$(/usr/local/vpnserver/vpncmd /server localhost /password:${ADMIN_HUB_PASSWORD} /adminhub:DEFAULT /cmd ServerInfoGet)

if [ $? -eq 0 ]; then
	echo "${softethervpn_auth_check}"
	echo "Successfully authenticated via admin hub. Importing Certificate now.."
	# Import Certificate
	/usr/local/vpnserver/vpncmd /server localhost /adminhub:"${HUBNAME}" /PASSWORD:"${ADMIN_HUB_PASSWORD}" /CMD ServerCertSet /LOADKEY:/etc/letsencrypt/live/"${VPN_HOSTNAME}"/privkey.pem /LOADCERT:/etc/letsencrypt/live/"${VPN_HOSTNAME}"/cert.pem
else
	echo "Authenticated failed please check password is specified correctly in config and rerun script" >&2
fi