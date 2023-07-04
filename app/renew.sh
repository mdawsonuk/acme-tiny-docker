#!/bin/bash

TODAY=`date '+%Y_%m_%d_%H_%M'`

# https://letsencrypt.org/docs/integration-guide/#supported-key-algorithms

function log() {
    NOW=`date '+%Y/%m/%d %H:%M:%S'`
    printf "${NOW} [acme_tiny]: ${1}"
}

function genRsa() {
    if [[ "${KEY_SIZE}" == "4096" ]]; then
        log "Generating fresh 4096 bit RSA private key... "
        openssl genrsa 4096 > /data/private.key 2> /dev/null
    elif [[ "${KEY_SIZE}" == "3072" ]]; then
        log "Generating fresh 3072 bit RSA private key... "
        openssl genrsa 3072 > /data/private.key 2> /dev/null
    elif [[ "${KEY_SIZE}" == "2048" ]]; then
        log "Generating fresh 2048 bit RSA private key... "
        openssl genrsa 2048 > /data/private.key 2> /dev/null
    else
        log "Key size not specified, defaulting to 2048 bits\n"
        log "Generating fresh 2048 bit RSA private key... "
        openssl genrsa 2048 > /data/private.key 2> /dev/null
    fi
}

function genEcdsa() {
    if [[ "${KEY_SIZE}" == "384" ]]; then
        log "Generating fresh 384 bit ECDSA private key... "
        openssl ecparam -name secp384r1 -genkey > /data/private.key 2> /dev/null
    elif [[ "${KEY_SIZE}" == "256" ]]; then
        log "Generating fresh 256 bit ECDSA private key... "
        openssl ecparam -name secp256r1 -genkey > /data/private.key 2> /dev/null
    else
        log "Key size not specified, defaulting to 256 bits\n"
        log "Generating fresh 256 bit ECDSA private key... "
        openssl ecparam -name secp256r1 -genkey > /data/private.key 2> /dev/null
    fi
}

function renew() {
    log "Creating fresh certificate for ${COMMON_NAME}\n"

    mkdir -p /data/challenges/
    chown -R www-data:www-data /data/challenges
    chmod 755 /data/challenges

    umask 077

    # Convert to lower case
    if [[ "${KEY_TYPE,,}" == "ecdsa" ]]; then
        genEcdsa
    elif [[ "${KEY_TYPE,,}" == "rsa" ]]; then
        genRsa
    else
        log "Key type not specified or invalid, defaulting to RSA\n"
        genRsa
    fi
    printf "Done\n"

    if [[ -z "${ALT_NAMES}" ]]; then
        log "Generating certificate signing request... "
        openssl req -new -sha256 -key /data/private.key -subj "/CN=${COMMON_NAME}" > /data/config/domain.csr
        printf "Done\n"
    else
        log "Generating certificate signing request with alt names... "
        AltNames=()

        IFS=';' read -ra NAMES <<< "${ALT_NAMES}"
        for name in "${NAMES[@]}"; do
            AltNames+=("DNS:$name")
        done

        subjectAltName=$(printf ", %s" "${AltNames[@]}")
        subjectAltName=${subjectAltName:2}

        if [ ! -z "${DEBUG}" ]; then
            log "subjectAltName = $subjectAltName\n"
        fi

        openssl req -new -sha256 -key /data/private.key -subj "/" -addext "subjectAltName = $subjectAltName" > /data/config/domain.csr
        printf "Done\n"
    fi

    umask 0022

    if [ "${DEBUG:-0}" == "1" ]; then
        openssl req -in /data/config/domain.csr -noout -text
    fi

    log "Running acme_tiny.py...\n"

    if [ ! -z "${STAGING}" ]; then
        if [ ! -z "${DISABLE_CHECK}" ]; then
            python3 /acme_tiny.py --account-key /data/config/account.key --disable-check --csr /data/config/domain.csr --acme-dir /data/challenges --directory-url https://acme-staging-v02.api.letsencrypt.org/directory > /data/certificate.crt
        else
            python3 /acme_tiny.py --account-key /data/config/account.key --csr /data/config/domain.csr --acme-dir /data/challenges --directory-url https://acme-staging-v02.api.letsencrypt.org/directory > /data/certificate.crt
        fi
    else
        if [ ! -z "${DISABLE_CHECK}" ]; then
            python3 /acme_tiny.py --account-key /data/config/account.key --disable-check --csr /data/config/domain.csr --acme-dir /data/challenges > /data/certificate.crt
        else
            python3 /acme_tiny.py --account-key /data/config/account.key --csr /data/config/domain.csr --acme-dir /data/challenges > /data/certificate.crt
        fi
    fi

    if [ "$?" -ne "0" ]; then
        log "Renewal failed...\n"

        log "\nTidying up... "
        rm /data/config/domain.csr 2> /dev/null
        rm /data/config/certificate.crt 2> /dev/null
        rm /data/config/private.key 2> /dev/null
        rm -rf /data/challenges 2> /dev/null
        printf "Done\n"

        exit 1
    fi

    log "Tidying up... "
    rm /data/config/domain.csr
    rm -rf /data/challenges
    printf "Done\n"

    if [ "${DEBUG:-0}" == "1" ]; then
        log "\nCertificate details:\n"
        openssl x509 -in /data/certificate.crt -text -noout
    fi

    log "Renewal complete - running post-hook.sh... "

    if [ -f /data/post-hook.sh ]; then
        /data/post-hook.sh
    fi

    printf "Done\n"
}

# Entrypoint

# Check if cert expires in the next 7 days (7 * 86400)
if [ ! -f /data/certificate.crt ]; then
    log "/data/certificate.crt doesn't exit, generating...\n"
    renew
elif ! openssl x509 -checkend 604800 -noout -in /data/certificate.crt > /dev/null; then
    cp /data/certificate.crt /data/expired/certificate_${TODAY}.crt
    cp /data/private.key /data/expired/certificate_${TODAY}.key
    log "\nCertificate expires in the next 7 days, attempting to renew...\n"
    renew
fi
