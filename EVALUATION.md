# Inception Evaluation Checklist

Run these checks inside the Inception virtual machine after creating `srcs/.env`, the four secret files and the host data directories.

## 1. Validate configuration

```bash
make config
```

The command must finish without a Compose validation error.

## 2. Clean boot

A clean boot is the most important test because it exercises database and WordPress initialization.

```bash
make fclean
make up
```

Then check:

```bash
docker ps
```

Expected running containers:

```text
nginx
wordpress
mariadb
```

## 3. Published ports

```bash
docker ps --format 'table {{.Names}}\t{{.Ports}}'
```

Only NGINX should publish a host port, and that port should be `443`.

MariaDB port `3306` and PHP-FPM port `9000` must remain internal to the Docker network.

## 4. NGINX configuration

```bash
docker exec nginx nginx -t
```

The syntax test must succeed.

## 5. WordPress installation

```bash
docker exec wordpress wp --allow-root --path=/var/www/html core is-installed
```

Exit status must be `0`.

List users:

```bash
docker exec wordpress wp --allow-root --path=/var/www/html user list
```

There must be an administrator account whose username does not contain `admin`, plus a second regular user.

## 6. MariaDB

List databases using the local root secret:

```bash
docker exec mariadb sh -c 'mariadb -u root -p"$(cat /run/secrets/db_root_password)" -e "SHOW DATABASES;"'
```

The WordPress database should exist.

Check the WordPress database user:

```bash
docker exec mariadb sh -c 'mariadb -u root -p"$(cat /run/secrets/db_root_password)" -e "SELECT User,Host FROM mysql.user;"'
```

## 7. Docker network

```bash
docker network ls
```

Inspect the project network if necessary:

```bash
docker network inspect srcs_inception
```

The three containers must share the same project network.

## 8. HTTPS and TLS

Make sure `vfidelis.42.fr` resolves to the VM IP, then test:

```bash
curl -kI https://vfidelis.42.fr
```

TLS 1.2:

```bash
openssl s_client -connect vfidelis.42.fr:443 -servername vfidelis.42.fr -tls1_2
```

TLS 1.3:

```bash
openssl s_client -connect vfidelis.42.fr:443 -servername vfidelis.42.fr -tls1_3
```

An old TLS version should not successfully negotiate with the server.

## 9. Persistence

Create or modify content in WordPress, then recreate containers without deleting the volumes:

```bash
make down
make up
```

The WordPress files, users and database content must still exist.

## 10. PID 1

```bash
docker exec mariadb ps -p 1 -o pid,comm,args
docker exec wordpress ps -p 1 -o pid,comm,args
docker exec nginx ps -p 1 -o pid,comm,args
```

The real service process should be PID 1 in each container.

## 11. Secrets and Git

```bash
git status --short
```

Secret `.txt` files must remain untracked/ignored. Never commit real passwords.

## 12. Final browser test

Open:

```text
https://vfidelis.42.fr
```

Confirm that the WordPress front-end loads and that `/wp-admin` is reachable through HTTPS.
