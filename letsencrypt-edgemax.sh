#!/bin/bash

################################################################

###  A script to renew and reload Let's Encrypt certificate
###  on Edgemax routers 
###
###  Copyright (c) 2017 Stephen Yip (aka kvic https://kazoo.ga)
###
###  Licensed for use under the MIT license 
###
###  History:
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
_today=$(date +%Y-%m-%e)
_certm=$(sudo stat -c %y ${home}/${domain}/${domain}.cer|awk '{print $1}')

[ "$_rv" -eq 0 -a "$_today" = "$_certm" ] && \
   logger "Let's Encrypt for ${domain} renewed. GUI restarting" && \
   sudo sh -c "cat ${home}/${domain}/${domain}.cer ${home}/${domain}/${domain}.key > $lighttpd_pem" && \
   sudo kill -SIGTERM $(cat /var/run/lighttpd.pid) && \
   sudo /usr/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf && exit

logger "Let's Encrypt for ${domain} not renewed. Probably not needed."
