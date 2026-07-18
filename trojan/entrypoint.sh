#!/bin/sh
set -eu

: "${TROJAN_DOMAIN:?ERROR: TROJAN_DOMAIN must be set}"

TROJAN_PORT="${TROJAN_PORT:-40443}"
CERT_DIR="${CERT_DIR:-/certs}"
TROJAN_CERT="${CERT_DIR}/${TROJAN_DOMAIN}.crt"
TROJAN_KEY="${CERT_DIR}/${TROJAN_DOMAIN}.key"

_creds_generated=0
if [ -z "${TROJAN_USER_PASSWORD:-}" ]; then
    TROJAN_USER_PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 24)
    _creds_generated=1
fi

echo "INFO: waiting for TLS certificate for ${TROJAN_DOMAIN} (synced from naive)..."
i=0
while [ ! -f "${TROJAN_CERT}" ] || [ ! -f "${TROJAN_KEY}" ]; do
    i=$((i + 1))
    if [ "$i" -ge 120 ]; then
        echo "ERROR: certificate for ${TROJAN_DOMAIN} not found under ${CERT_DIR}" >&2
        echo "       Make sure the cert-sync container is running and naive has issued a certificate for this domain." >&2
        exit 1
    fi
    sleep 2
done

sed \
    -e "s|TROJAN_PORT|${TROJAN_PORT}|g" \
    -e "s|TROJAN_USER_PASSWORD|${TROJAN_USER_PASSWORD}|g" \
    -e "s|TROJAN_CERT_PATH|${TROJAN_CERT}|g" \
    -e "s|TROJAN_KEY_PATH|${TROJAN_KEY}|g" \
    /etc/trojan/config.json.tmpl > /etc/trojan/config.json

echo "============================================"
echo " Trojan Proxy"
echo "--------------------------------------------"
echo " Domain    : ${TROJAN_DOMAIN}"
echo " Port      : ${TROJAN_PORT}"
if [ "${_creds_generated}" = "1" ]; then
    echo " Password  : ${TROJAN_USER_PASSWORD}"
    echo ""
    echo " NOTE: Password was auto-generated."
    echo "       Set TROJAN_USER_PASSWORD in .env"
    echo "       to keep it across restarts."
fi
echo "============================================"

exec trojan -c /etc/trojan/config.json
