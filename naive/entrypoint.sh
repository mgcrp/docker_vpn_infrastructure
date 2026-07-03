#!/bin/sh
set -eu

: "${NAIVE_DOMAIN:?ERROR: NAIVE_DOMAIN must be set}"
: "${NAIVE_EMAIL:?ERROR: NAIVE_EMAIL must be set}"

NAIVE_HTTP_PORT="${NAIVE_HTTP_PORT:-80}"
NAIVE_HTTPS_PORT="${NAIVE_HTTPS_PORT:-443}"
NAIVE_USER_NAME="${NAIVE_USER_NAME:-naive}"
NAIVE_MASK_SITE="${NAIVE_MASK_SITE:-yastatic.net}"

_creds_generated=0
if [ -z "${NAIVE_USER_PASSWORD:-}" ]; then
    NAIVE_USER_PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 24)
    _creds_generated=1
fi

sed \
    -e "s|NAIVE_HTTPS_PORT|${NAIVE_HTTPS_PORT}|g" \
    -e "s|NAIVE_HTTP_PORT|${NAIVE_HTTP_PORT}|g" \
    -e "s|NAIVE_DOMAIN|${NAIVE_DOMAIN}|g" \
    -e "s|NAIVE_EMAIL|${NAIVE_EMAIL}|g" \
    -e "s|NAIVE_USER_NAME|${NAIVE_USER_NAME}|g" \
    -e "s|NAIVE_USER_PASSWORD|${NAIVE_USER_PASSWORD}|g" \
    -e "s|NAIVE_MASK_SITE|${NAIVE_MASK_SITE}|g" \
    /etc/caddy/Caddyfile.tmpl > /etc/caddy/Caddyfile

echo "============================================"
echo " NaiveProxy (Caddy + forwardproxy)"
echo "--------------------------------------------"
echo " Domain    : ${NAIVE_DOMAIN}"
echo " Port      : ${NAIVE_HTTPS_PORT}"
echo " Mask site : ${NAIVE_MASK_SITE}"
echo " User      : ${NAIVE_USER_NAME}"
if [ "${_creds_generated}" = "1" ]; then
    echo " Password  : ${NAIVE_USER_PASSWORD}"
    echo ""
    echo " NOTE: Password was auto-generated."
    echo "       Set NAIVE_USER_PASSWORD in .env"
    echo "       to keep it across restarts."
fi
echo "============================================"

exec caddy run --environ --config /etc/caddy/Caddyfile
