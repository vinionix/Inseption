# Inception Evaluation Checklist

Use this checklist inside the Inception virtual machine. Before starting, create `srcs/.env` from `srcs/.env.example` and create the four local secret files described in `srcs/secrets/README.md`.

This checklist follows the mandatory evaluation flow closely and intentionally includes destructive and persistence tests.

## 1. Repository and configuration

Confirm that the repository contains the root `Makefile`, the `srcs/` directory, one Dockerfile per mandatory service, and no committed credentials.

```bash
git status --short
git ls-files srcs/.env 'srcs/secrets/*.txt'
make config
```

`git ls-files` must not list the real `.env` or secret `.txt` files, and Compose validation must succeed.

## 2. Forbidden Docker patterns

Review the Compose file, Dockerfiles and startup scripts. There must be no host networking, links, infinite keepalive commands, or service process kept alive through a shell trick.

```bash
grep -RniE 'network_mode:[[:space:]]*host|network:[[:space:]]*host|links:|--link|tail[[:space:]]+-f|sleep[[:space:]]+infinity|while[[:space:]]+true' \
	Makefile srcs || true
```

A bounded readiness loop is acceptable; a fake infinite keepalive is not.

## 3. Clean build

Build and start the project through the Makefile:

```bash
make up
```

Then verify that all mandatory containers are running and have not crashed:

```bash
docker compose -f srcs/docker-compose.yml --env-file srcs/.env ps
docker ps
```

Expected services:

```text
nginx
wordpress
mariadb
```

## 4. Images and PID 1

Each mandatory service must use its own Dockerfile and image.

```bash
docker images --format 'table {{.Repository}}\t{{.Tag}}'
```

Check the main process of every container:

```bash
docker exec mariadb ps -p 1 -o pid,comm,args
docker exec wordpress ps -p 1 -o pid,comm,args
docker exec nginx ps -p 1 -o pid,comm,args
```

The real service must be PID 1: MariaDB, PHP-FPM and NGINX respectively.

## 5. Published ports

```bash
docker ps --format 'table {{.Names}}\t{{.Ports}}'
```

Only NGINX may publish a host port, and the only published application port must be `443`. MariaDB `3306` and PHP-FPM `9000` remain internal to the Docker network.

HTTP on port 80 must fail:

```bash
curl -I --connect-timeout 3 http://vfidelis.42.fr || true
```

HTTPS must work:

```bash
curl -kI https://vfidelis.42.fr
```

## 6. NGINX and TLS

Validate NGINX configuration:

```bash
docker exec nginx nginx -t
```

Demonstrate TLS 1.2:

```bash
echo | openssl s_client \
	-connect vfidelis.42.fr:443 \
	-servername vfidelis.42.fr \
	-tls1_2 2>/dev/null | grep Protocol
```

Demonstrate TLS 1.3:

```bash
echo | openssl s_client \
	-connect vfidelis.42.fr:443 \
	-servername vfidelis.42.fr \
	-tls1_3 2>/dev/null | grep Protocol
```

An old TLS version must not successfully negotiate:

```bash
echo | openssl s_client \
	-connect vfidelis.42.fr:443 \
	-servername vfidelis.42.fr \
	-tls1_1
```

A warning for the self-signed certificate is acceptable.

## 7. Docker network

```bash
docker network ls
docker network inspect srcs_inception
```

The three containers must share the project bridge network. There must be no `network: host` or `links` configuration.

## 8. Volumes

List and inspect the two mandatory volumes:

```bash
docker volume ls
docker volume inspect srcs_mariadb_data
docker volume inspect srcs_wordpress_data
```

The inspect output must show the host paths under:

```text
/home/vfidelis/data/mariadb
/home/vfidelis/data/wordpress
```

## 9. WordPress installation and users

```bash
docker exec wordpress wp --allow-root \
	--path=/var/www/html core is-installed

docker exec wordpress wp --allow-root \
	--path=/var/www/html user list
```

`core is-installed` must return success. There must be an administrator account whose username does not contain `admin` or `Admin`, plus a second regular user.

Open:

```text
https://vfidelis.42.fr
https://vfidelis.42.fr/wp-admin
```

The WordPress installation wizard must not appear.

During the evaluation, also demonstrate both interactive actions required by the scale:

1. Sign in with the regular WordPress user and add a comment.
2. Sign in with the administrator, edit a page, then refresh the public website and show that the change is visible.

## 10. MariaDB

Log in using the root secret and show that the database is not empty:

```bash
docker exec mariadb sh -c \
	'mariadb -u root -p"$(cat /run/secrets/db_root_password)" -e "SHOW DATABASES; USE wordpress; SHOW TABLES;"'
```

Check the database users:

```bash
docker exec mariadb sh -c \
	'mariadb -u root -p"$(cat /run/secrets/db_root_password)" -e "SELECT User,Host FROM mysql.user;"'
```

The WordPress database and its tables must exist.

## 11. Container recreation

Recreate the containers without deleting persistent data:

```bash
make down
make up
```

Verify that the users, page changes and database content still exist.

## 12. Full VM persistence test

This is distinct from recreating containers. Make a visible edit to the WordPress site, then reboot the virtual machine:

```bash
sudo reboot
```

After the VM starts again:

```bash
cd ~/Inseption
make up
curl -kI https://vfidelis.42.fr
```

Open the website and confirm that the WordPress configuration, users, database and the visible edit made before the reboot are still present.

## 13. Final browser test

The final mandatory path is:

```text
browser -> NGINX:443 -> PHP-FPM:9000 -> MariaDB:3306
```

Confirm that `https://vfidelis.42.fr` loads the configured WordPress site, while port 80, MariaDB and PHP-FPM are not exposed directly to the host.
