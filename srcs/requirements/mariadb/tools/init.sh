#!/bin/sh

set -eu

unset MYSQL_HOST

DATA_DIR="/var/lib/mysql"
BOOTSTRAP_LOG="/tmp/mariadb-bootstrap.log"

mkdir -p /run/mysqld "${DATA_DIR}"
chown -R mysql:mysql /run/mysqld "${DATA_DIR}"

for secret in \
	/run/secrets/db_password \
	/run/secrets/db_root_password
do
	if [ ! -r "${secret}" ]; then
		echo "Error: missing secret ${secret}"
		exit 1
	fi
done

: "${MYSQL_DATABASE:?MYSQL_DATABASE is required}"
: "${MYSQL_USER:?MYSQL_USER is required}"

DB_PASSWORD=$(cat /run/secrets/db_password)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

if [ ! -d "${DATA_DIR}/mysql" ]; then
	echo "Initializing MariaDB database..."

	mariadb-install-db \
		--user=mysql \
		--datadir="${DATA_DIR}" \
		--auth-root-authentication-method=normal

	echo "Configuring MariaDB database..."

	if ! mariadbd \
		--user=mysql \
		--datadir="${DATA_DIR}" \
		--bootstrap >"${BOOTSTRAP_LOG}" 2>&1 <<EOF
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
ALTER USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
DROP USER IF EXISTS ''@'localhost';
DROP USER IF EXISTS ''@'${HOSTNAME}';
DROP DATABASE IF EXISTS \`test\`;
FLUSH PRIVILEGES;
EOF
	then
		cat "${BOOTSTRAP_LOG}"
		echo "Error: MariaDB bootstrap failed."
		exit 1
	fi

	cat "${BOOTSTRAP_LOG}"
	if grep -q "ERROR" "${BOOTSTRAP_LOG}"; then
		echo "Error: MariaDB bootstrap reported an SQL error."
		exit 1
	fi
	rm -f "${BOOTSTRAP_LOG}"
fi

echo "Starting MariaDB..."
exec mariadbd --user=mysql --datadir="${DATA_DIR}" --console
