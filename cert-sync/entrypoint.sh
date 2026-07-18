#!/bin/sh
set -eu

: "${NAIVE_DOMAIN:?ERROR: NAIVE_DOMAIN must be set}"

SRC_DIR="${NAIVE_CERT_DIR:-/naive-data/caddy/certificates}"
DST_DIR="${SHARED_CERT_DIR:-/shared-certs}"
INTERVAL="${CERT_SYNC_INTERVAL:-3600}"

sync_once() {
    src_crt=$(find "${SRC_DIR}" -type f -name "${NAIVE_DOMAIN}.crt" -path "*/${NAIVE_DOMAIN}/*" 2>/dev/null | head -n1)
    src_key=$(find "${SRC_DIR}" -type f -name "${NAIVE_DOMAIN}.key" -path "*/${NAIVE_DOMAIN}/*" 2>/dev/null | head -n1)
    if [ -z "${src_crt}" ] || [ -z "${src_key}" ]; then
        return 1
    fi
    if ! cmp -s "${src_crt}" "${DST_DIR}/${NAIVE_DOMAIN}.crt" 2>/dev/null; then
        cp "${src_crt}" "${DST_DIR}/${NAIVE_DOMAIN}.crt.tmp"
        mv "${DST_DIR}/${NAIVE_DOMAIN}.crt.tmp" "${DST_DIR}/${NAIVE_DOMAIN}.crt"
        cp "${src_key}" "${DST_DIR}/${NAIVE_DOMAIN}.key.tmp"
        mv "${DST_DIR}/${NAIVE_DOMAIN}.key.tmp" "${DST_DIR}/${NAIVE_DOMAIN}.key"
        chmod 644 "${DST_DIR}/${NAIVE_DOMAIN}.crt"
        chmod 600 "${DST_DIR}/${NAIVE_DOMAIN}.key"
        echo "INFO: synced certificate for ${NAIVE_DOMAIN}"
    fi
    return 0
}

echo "INFO: waiting for initial certificate for ${NAIVE_DOMAIN}..."
i=0
until sync_once; do
    i=$((i + 1))
    if [ "$i" -ge 120 ]; then
        echo "ERROR: certificate for ${NAIVE_DOMAIN} not found under ${SRC_DIR} after waiting" >&2
        exit 1
    fi
    sleep 2
done
echo "INFO: initial certificate synced to ${DST_DIR}, will re-check every ${INTERVAL}s for renewals"

while :; do
    sleep "${INTERVAL}"
    sync_once || echo "WARN: certificate temporarily missing during sync check" >&2
done
