#!/bin/bash

function log() {
    NOW=`date '+%Y/%m/%d %H:%M:%S'`
    printf "${NOW} [acme_tiny]: ${1}"
}

log "acme_tiny starting up...\n"

if [[ -z "${COMMON_NAME}" ]]; then
    log "Mandatory environmental variable COMMON_NAME not set, exiting\n"
    exit 1
else
    log "Setting up certificate renewal for ${COMMON_NAME}\n"
fi

if [[ ! -z "${ALT_NAMES}" ]]; then
    log "Identified Alt Names for certificate: ${ALT_NAMES}\n"
fi

cron

mkdir -p /data/config
mkdir -p /data/expired

if [ ! -f /data/config/account.key ]; then
    log "account.key doesn't exit, creating... "
    umask 077
    openssl genrsa 4096 > /data/config/account.key 2>/dev/null
    printf "Done\n"
fi

# Do this so cron can access the environmental variables
printenv | grep -v "no_proxy" >> /etc/environment

# Delay a run of the renew.sh script so we get the cert generated on startup if it doesn't exist
( sleep 5 ; /app/renew.sh > /proc/1/fd/1 2>/proc/1/fd/2 ) &

log "Starting Nginx\n"

nginx -g "daemon off;"
