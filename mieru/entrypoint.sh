#!/bin/sh
set -eu

MIERU_CONFIG_FILE="${MIERU_CONFIG_FILE:-/config/mieru-users.json}"

if [ ! -f "${MIERU_CONFIG_FILE}" ]; then
    echo "ERROR: config file not found at ${MIERU_CONFIG_FILE}" >&2
    echo "       Copy mieru/mieru-users.json.example to mieru/mieru-users.json and edit it." >&2
    exit 1
fi

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

mita apply config "${MIERU_CONFIG_FILE}"
mita start

echo "============================================"
echo " MieruProxy (mita) started"
echo "============================================"
mita describe config

wait "$MITA_PID"
