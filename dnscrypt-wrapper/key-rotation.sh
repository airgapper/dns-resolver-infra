#!/bin/sh

sleep 1800

KEYS_DIR="/opt/dnscrypt/etc/keys"
STKEYS_DIR="${KEYS_DIR}/short-term"
# DNSCRYPT_KEY_DIR=${DNSCRYPT_KEY_DIR:-"/opt/dnscrypt"}

rotation_needed() {
    if [ $(/usr/bin/find "$STKEYS_DIR" -type f -cmin -720 -print -quit | wc -l | sed 's/[^0-9]//g') -le 0 ]; then
        echo true
    else
        echo false
    fi
}

[ $(rotation_needed) = true ] || exit 0
sv status dnscrypt-wrapper | grep -E -q '^run:' || exit 0
sv restart dnscrypt-wrapper
