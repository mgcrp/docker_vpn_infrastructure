#!/bin/sh
set -eu

: "${MIERU_PORT:?ERROR: MIERU_PORT must be set}"

MIERU_USER_NAME="${MIERU_USER_NAME:-mieru}"

_creds_generated=0
if [ -z "${MIERU_USER_PASSWORD:-}" ]; then
    MIERU_USER_PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16)
    _creds_generated=1
fi

QUOTA_JSON=""
if [ -n "${MIERU_QUOTA_DAYS:-}" ] && [ -n "${MIERU_QUOTA_GB:-}" ]; then
    QUOTA_JSON=",\"quotas\":[{\"days\":${MIERU_QUOTA_DAYS},\"megabytes\":$((MIERU_QUOTA_GB * 1024))}]"
fi

cat > /tmp/mieru-config.json <<EOF
{
    "portBindings": [
        {
            "port": ${MIERU_PORT},
            "protocol": "TCP"
        }
    ],
    "users": [
        {
            "name": "${MIERU_USER_NAME}",
            "password": "${MIERU_USER_PASSWORD}"${QUOTA_JSON}
        }
    ]
}
EOF

mita run &
MITA_PID=$!
trap 'kill -TERM "$MITA_PID" 2>/dev/null; wait "$MITA_PID"' TERM INT

i=0
while [ ! -S /var/run/mita/mita.sock ]; do
    i=$((i + 1))
    if [ "$i" -ge 30 ]; then
        echo "ERROR: mita daemon socket did not appear in time" >&2
        exit 1
    fi
    sleep 1
done

mita apply config /tmp/mieru-config.json
mita start

echo "============================================"
echo " MieruProxy (mita)"
echo "--------------------------------------------"
echo " Port      : ${MIERU_PORT}/tcp"
echo " User      : ${MIERU_USER_NAME}"
if [ "${_creds_generated}" = "1" ]; then
    echo " Password  : ${MIERU_USER_PASSWORD}"
    echo ""
    echo " NOTE: Password was auto-generated."
    echo "       Set MIERU_USER_PASSWORD in .env"
    echo "       to keep it across restarts."
fi
echo "============================================"

mita describe config

wait "$MITA_PID"
