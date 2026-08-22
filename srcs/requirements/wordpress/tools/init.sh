#!/bin/sh

set -e

WP_PATH="/var/www/html"

mkdir -p /run/php
mkdir -p "${WP_PATH}"

for secret in \
	/run/secrets/db_password \
	/run/secrets/wp_password \
	/run/secrets/wp_root_password
do
	if [ ! -r "${secret}" ]; then
		echo "Error: missing secret ${secret}"
		exit 1
	fi
done

DB_PASSWORD=$(cat /run/secrets/db_password)

echo "Waiting for MariaDB..."

attempt=0

until mariadb-admin ping \
	-h "${WORDPRESS_DB_HOST}" \
	-u "${MYSQL_USER}" \
	-p"${DB_PASSWORD}" \
	--silent
do
	attempt=$((attempt + 1))

	if [ "${attempt}" -ge 30 ]; then
		echo "Error: MariaDB did not become ready."
		exit 1
	fi

	sleep 2
done

echo "MariaDB is ready."

if [ ! -f "${WP_PATH}/wp-includes/version.php" ]; then
	echo "Downloading WordPress..."

	wp --allow-root \
		--path="${WP_PATH}" \
		core download \
		--locale=pt_BR
fi

if [ ! -f "${WP_PATH}/wp-config.php" ]; then
	echo "Creating wp-config.php..."

	wp --allow-root \
		--quiet \
		--path="${WP_PATH}" \
		config create \
		--dbname="${MYSQL_DATABASE}" \
		--dbuser="${MYSQL_USER}" \
		--dbhost="${WORDPRESS_DB_HOST}" \
		--prompt=dbpass \
		< /run/secrets/db_password > /dev/null
fi

if ! wp --allow-root \
	--path="${WP_PATH}" \
	core is-installed
then
	echo "Installing WordPress..."

	wp --allow-root \
		--quiet \
		--path="${WP_PATH}" \
		core install \
		--url="https://${DOMAIN_NAME}" \
		--title="${WP_TITLE}" \
		--admin_user="${WP_ADMIN_USER}" \
		--admin_email="${WP_ADMIN_EMAIL}" \
		--skip-email \
		--prompt=admin_password \
		< /run/secrets/wp_root_password > /dev/null
fi

if ! wp --allow-root \
	--path="${WP_PATH}" \
	user get "${WP_USER}" \
	--field=ID > /dev/null 2>&1
then
	echo "Creating WordPress user..."

	wp --allow-root \
		--quiet \
		--path="${WP_PATH}" \
		user create \
		"${WP_USER}" \
		"${WP_USER_EMAIL}" \
		--role=author \
		--prompt=user_pass \
		< /run/secrets/wp_password > /dev/null
fi

chown -R www-data:www-data "${WP_PATH}"

echo "Starting PHP-FPM..."

exec php-fpm8.2 -F
