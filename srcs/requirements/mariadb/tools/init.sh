#!/bin/sh

set -e

unset MYSQL_HOST
mkdir -p /run/mysqld
mkdir -p /var/lib/mysql

chown -R mysql:mysql /run/mysqld /var/lib/mysql

DB_PASSWORD=$(cat /run/secrets/db_password)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB database..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql

    mariadbd \
        --user=mysql \
        --datadir=/var/lib/mysql \
        --socket=/run/mysqld/mysqld.sock \
        --skip-networking &

until mariadb-admin ping --socket=/run/mysqld/mysqld.sock --silent; do
	sleep 1
done

mariadb -u root --socket=/run/mysqld/mysqld.sock << EOF
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

DROP DATABASE IF EXISTS `test`;

FLUSH PRIVILEGES;
EOF

    mariadb-admin \
        -u root \
        -p"${DB_ROOT_PASSWORD}" \
        --socket=/run/mysqld/mysqld.sock \
        shutdown
fi

echo "Starting MariaDB..."
exec mariadbd --user=mysql --datadir=/var/lib/mysql --console