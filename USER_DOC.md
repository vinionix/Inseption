# User Documentation

## Services provided

The stack provides three services:

- **NGINX**: HTTPS entrypoint on port `443`.
- **WordPress + PHP-FPM**: website and PHP runtime.
- **MariaDB**: persistent WordPress database.

Only NGINX is directly exposed to the host.

## Prerequisites

The project must run inside the Inception Linux virtual machine with Docker, Docker Compose and Make installed.

Create the public configuration file when needed:

```bash
cp srcs/.env.example srcs/.env
```

## Credentials and secrets

Passwords are stored locally in:

```text
srcs/secrets/db_password.txt
srcs/secrets/db_root_password.txt
srcs/secrets/wp_password.txt
srcs/secrets/wp_root_password.txt
```

Recommended permissions:

```bash
chmod 600 srcs/secrets/*.txt
```

These files must not be committed to Git. Public usernames, emails, database names and the domain are configured in `srcs/.env`.

## Start the infrastructure

From the repository root:

```bash
make
```

or:

```bash
make up
```

The Makefile checks the local configuration and secrets, creates the persistent host directories and starts the Compose stack.

## Stop the infrastructure

```bash
make down
```

This removes the containers while preserving persistent project data.

## Access the site

Front-end:

```text
https://vfidelis.42.fr
```

Administration panel:

```text
https://vfidelis.42.fr/wp-admin
```

The domain must resolve to the virtual machine IP from the computer running the browser.

The project uses a self-signed TLS certificate, so the browser may display a certificate warning during local evaluation.

## WordPress users

The administrator username and email are configured through `srcs/.env`. Its password is read from `wp_root_password.txt`.

A second regular WordPress user is also created. Its password is read from `wp_password.txt`.

## Check service status

```bash
make status
```

or:

```bash
docker ps
```

Expected containers:

```text
nginx
wordpress
mariadb
```

Only NGINX should publish port `443` to the host.

## View logs

All services:

```bash
make logs
```

Individual services:

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

## Validate configuration

```bash
make config
```

This asks Docker Compose to render and validate the current configuration without starting new services.

## Persistent data

Project data is stored under:

```text
/home/vfidelis/data/mariadb
/home/vfidelis/data/wordpress
```

Stopping or recreating containers does not remove this data unless the volumes or host data directories are explicitly deleted.

## Full reset

```bash
make fclean
```

This is destructive. It removes project containers, images, volumes and the persistent project data directories.

## Final checks

Before peer evaluation, follow [`EVALUATION.md`](EVALUATION.md) to test clean startup, TLS, ports, users, database access, persistence and PID 1 behavior.
