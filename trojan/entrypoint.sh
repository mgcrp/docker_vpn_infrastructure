#!/bin/sh
set -eu

: "${TROJAN_DOMAIN:?ERROR: TROJAN_DOMAIN must be set}"

TROJAN_PORT="${TROJAN_PORT:-40443}"
NAIVE_CERT_DIR="${NAIVE_CERT_DIR:-/naive-data/caddy/certificates}"

_creds_generated=0
if [ -z "${TROJAN_USER_PASSWORD:-}" ]; then
    TROJAN_USER_PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 24)
    _creds_generated=1
fi

echo "INFO: waiting for TLS certificate for ${TROJAN_DOMAIN} (issued by naive)..."
i=0
while :; do
    TROJAN_CERT=$(find "${NAIVE_CERT_DIR}" -type f -name "${TROJAN_DOMAIN}.crt" -path "*/${TROJAN_DOMAIN}/*" 2>/dev/null | head -n1)
    TROJAN_KEY=$(find "${NAIVE_CERT_DIR}" -type f -name "${TROJAN_DOMAIN}.key" -path "*/${TROJAN_DOMAIN}/*" 2>/dev/null | head -n1)
    if [ -n "${TROJAN_CERT}" ] && [ -n "${TROJAN_KEY}" ]; then
        break
    fi
    i=$((i + 1))
    if [ "$i" -ge 120 ]; then
        echo "ERROR: certificate for ${TROJAN_DOMAIN} not found under ${NAIVE_CERT_DIR}" >&2
        echo "       Make sure the naive container is running and has issued a certificate for this domain." >&2
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
