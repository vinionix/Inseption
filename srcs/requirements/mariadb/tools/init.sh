#!/bin/sh

set -eu

unset MYSQL_HOST

DATA_DIR="/var/lib/mysql"
SOCKET="/run/mysqld/mysqld.sock"

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
	mariadb-install-db --user=mysql --datadir="${DATA_DIR}"

	mariadbd \
		--user=mysql \
		--datadir="${DATA_DIR}" \
		--socket="${SOCKET}" \
		--skip-networking &

	server_pid=$!
	attempt=0

	until mariadb-admin ping \
		--protocol=socket \
		--socket="${SOCKET}" \
		--silent
	do
		attempt=$((attempt + 1))
		if [ "${attempt}" -ge 30 ]; then
			echo "Error: temporary MariaDB server did not become ready."
			kill "${server_pid}" 2>/dev/null || true
			exit 1
		fi
		sleep 1
	done

	mariadb \
		--protocol=socket \
		--socket="${SOCKET}" \
		-u root <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%'
	IDENTIFIED BY '${DB_PASSWORD}';

ALTER USER '${MYSQL_USER}'@'%'
	IDENTIFIED BY '${DB_PASSWORD}';

GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.*
	TO '${MYSQL_USER}'@'%';

ALTER USER 'root'@'localhost'
	IDENTIFIED BY '${DB_ROOT_PASSWORD}';

DROP USER IF EXISTS ''@'localhost';
DROP USER IF EXISTS ''@'${HOSTNAME}';
DROP DATABASE IF EXISTS \`test\`;

FLUSH PRIVILEGES;
EOF

	mariadb-admin \
		-u root \
		-p"${DB_ROOT_PASSWORD}" \
		--protocol=socket \
		--socket="${SOCKET}" \
		shutdown

	wait "${server_pid}" 2>/dev/null || true
fi

echo "Starting MariaDB..."
exec mariadbd --user=mysql --datadir="${DATA_DIR}" --console
