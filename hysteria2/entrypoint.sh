#!/bin/sh
set -eu

: "${HYSTERIA2_DOMAIN:?ERROR: HYSTERIA2_DOMAIN must be set}"

HYSTERIA2_PORT="${HYSTERIA2_PORT:-50443}"
NAIVE_CERT_DIR="${NAIVE_CERT_DIR:-/naive-data/caddy/certificates}"

_creds_generated=0
if [ -z "${HYSTERIA2_PASSWORD:-}" ]; then
    HYSTERIA2_PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 24)
    _creds_generated=1
fi

echo "INFO: waiting for TLS certificate for ${HYSTERIA2_DOMAIN} (issued by naive)..."
i=0
while :; do
    HYSTERIA2_CERT=$(find "${NAIVE_CERT_DIR}" -type f -name "${HYSTERIA2_DOMAIN}.crt" -path "*/${HYSTERIA2_DOMAIN}/*" 2>/dev/null | head -n1)
    HYSTERIA2_KEY=$(find "${NAIVE_CERT_DIR}" -type f -name "${HYSTERIA2_DOMAIN}.key" -path "*/${HYSTERIA2_DOMAIN}/*" 2>/dev/null | head -n1)
    if [ -n "${HYSTERIA2_CERT}" ] && [ -n "${HYSTERIA2_KEY}" ]; then
        break
    fi
    i=$((i + 1))
    if [ "$i" -ge 120 ]; then
        echo "ERROR: certificate for ${HYSTERIA2_DOMAIN} not found under ${NAIVE_CERT_DIR}" >&2
        echo "       Make sure the naive container is running and has issued a certificate for this domain." >&2
        exit 1
    fi
    sleep 2
done

sed \
    -e "s|HYSTERIA2_PORT|${HYSTERIA2_PORT}|g" \
    -e "s|HYSTERIA2_PASSWORD|${HYSTERIA2_PASSWORD}|g" \
    -e "s|HYSTERIA2_CERT_PATH|${HYSTERIA2_CERT}|g" \
    -e "s|HYSTERIA2_KEY_PATH|${HYSTERIA2_KEY}|g" \
    /hysteria/config.yaml.tmpl > /tmp/config.yaml

echo "============================================"
echo " Hysteria2 Proxy"
echo "--------------------------------------------"
echo " Domain    : ${HYSTERIA2_DOMAIN}"
echo " Port      : ${HYSTERIA2_PORT}"
if [ "${_creds_generated}" = "1" ]; then
    echo " Password  : ${HYSTERIA2_PASSWORD}"
    echo ""
    echo " NOTE: Password was auto-generated."
    echo "       Set HYSTERIA2_PASSWORD in .env"
    echo "       to keep it across restarts."
fi
echo "============================================"

exec hysteria server -c /tmp/config.yaml
