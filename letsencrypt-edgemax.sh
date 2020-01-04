#!/usr/bin/env bash

################################################################

###  A script to renew and reload Let's Encrypt certificate
###  on Edgemax routers
###
###  Copyright (c) 2017-2019 Stephen Yip (aka kvic) https://kazoo.ga
###
###  Licensed for use under the MIT license 
###
###  History:
###      Apr 15, 2019 Updated to work on both FW v1.x and v2.x
###      Sep 12, 2017 Initial release

################################################################

###### CHANGE TO SUIT YOUR SETUP ######

### 'home' - where you installed acme.sh
### 'domain' - for your Edgemax GUI
### 'lighttpd_pem' - certificate file configured for your Edgemax GUI

home=/config/user-data/acme.sh
domain=erx.yourdomain.com
lighttpd_pem=/config/auth/erx.yourdomain.com.pem

### For testing, uncomment below to force renewal

#force='--force' 

###### SHALL NOT REQUIRE ADAPTATION FROM HERE ON ######

sudo LE_WORKING_DIR=${home} ${home}/acme.sh --renew -d ${domain} --days 70 ${force} > /dev/null

_rv=$?
_today=$(date +%Y-%m-%d)
_certm=$(sudo stat -c %y ${home}/${domain}/${domain}.cer|awk '{print $1}')

if (( $_rv != 0 )) || [[ "$_today" != "$_certm" ]]; then
    logger "Let's Encrypt not renewed. Perhaps no need."
    exit
fi

logger "Let's Encrypt renewed for ${domain}. Restarting GUI..."
sudo sh -c "cat ${home}/${domain}/${domain}.cer ${home}/${domain}/${domain}.key > $lighttpd_pem"

(( $(uname -r|cut -d '.' -f 1) >= 4 )) && {
    sudo systemctl restart lighttpd.service
} || {
    sudo kill -SIGTERM $(cat /var/run/lighttpd.pid)
    sudo /usr/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf
}
