#!/bin/sh
set -eu

: "${CADVISOR_AUTH_USER:?ERROR: CADVISOR_AUTH_USER must be set}"
: "${CADVISOR_AUTH_PASSWORD:?ERROR: CADVISOR_AUTH_PASSWORD must be set}"

htpasswd -cbB /etc/nginx/.htpasswd "${CADVISOR_AUTH_USER}" "${CADVISOR_AUTH_PASSWORD}"

echo "============================================"
echo " cAdvisor basic-auth proxy"
echo "--------------------------------------------"
echo " User : ${CADVISOR_AUTH_USER}"
echo "============================================"

exec nginx -g "daemon off;"
