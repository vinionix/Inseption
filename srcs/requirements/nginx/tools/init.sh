#!/bin/sh

set -e

SSL_DIR="/etc/nginx/ssl"
CERT_FILE="${SSL_DIR}/inception.crt"
KEY_FILE="${SSL_DIR}/inception.key"

mkdir -p "${SSL_DIR}"

if [ ! -f "${CERT_FILE}" ] || [ ! -f "${KEY_FILE}" ]; then
	echo "Generating TLS certificate..."

	openssl req -x509 \
		-nodes \
		-days 365 \
		-newkey rsa:2048 \
		-keyout "${KEY_FILE}" \
		-out "${CERT_FILE}" \
		-subj "/C=BR/ST=Rio de Janeiro/L=Rio de Janeiro/O=42/OU=42Rio/CN=${DOMAIN_NAME}"
fi

chmod 600 "${KEY_FILE}"

echo "Starting NGINX..."

exec nginx -g "daemon off;"