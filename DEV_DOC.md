# Developer Documentation

## Project structure

```text
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
└── srcs
    ├── .env
    ├── .env.example
    ├── docker-compose.yml
    ├── secrets
    └── requirements
        ├── mariadb
        ├── wordpress
        └── nginx
```

Each service is built from its own Dockerfile. No application service image is used directly.

## Architecture

```text
Client
  |
  | HTTPS :443
  v
NGINX
  |
  | FastCGI
  v
WordPress / PHP-FPM :9000
  |
  | TCP
  v
MariaDB :3306
```

NGINX is the only service with a host-published port. WordPress and MariaDB remain reachable only from the internal Docker network.

## MariaDB

The MariaDB image is based on Debian and installs the database server with `apt`.

The startup script:

1. prepares MariaDB runtime directories;
2. reads database passwords from `/run/secrets`;
3. initializes the data directory only when necessary;
4. creates the WordPress database and database user;
5. configures the local root password;
6. removes anonymous users and the test database;
7. starts `mariadbd` in foreground as PID 1.

MariaDB listens on port `3306` inside the Docker network but does not publish that port to the host.

## WordPress and PHP-FPM

The WordPress image installs PHP, PHP-FPM, the required PHP extensions, MariaDB client utilities and WP-CLI.

The startup script waits for MariaDB, downloads WordPress if necessary, creates `wp-config.php`, installs the site and creates the configured users.

PHP-FPM listens on:

```text
0.0.0.0:9000
```

This makes the FastCGI service available to NGINX through the internal Docker network without publishing port `9000` to the host.

The main process is PHP-FPM in foreground mode.

## NGINX

NGINX is the HTTPS entrypoint.

Its startup script generates a self-signed certificate when the certificate files are absent and then starts NGINX in foreground mode.

The NGINX configuration:

- listens on port `443` with SSL enabled;
- permits TLS 1.2 and TLS 1.3;
- serves static WordPress files from `/var/www/html`;
- forwards PHP requests to `wordpress:9000` through FastCGI;
- sends access and error logs to container stdout/stderr.

## Docker network

All services join the `inception` Docker network.

Compose service names act as internal DNS names. For example:

```text
wordpress:9000
mariadb:3306
```

No fixed container IP addresses are required.

## Volumes

Two persistent named volumes are used:

- MariaDB data mounted at `/var/lib/mysql`;
- WordPress files mounted at `/var/www/html`.

The volumes use host-backed storage under:

```text
/home/vfidelis/data/mariadb
/home/vfidelis/data/wordpress
```

The WordPress volume is also mounted in the NGINX container so NGINX can serve static files while PHP execution remains in the WordPress container.

## Environment and secrets

Public configuration belongs in `srcs/.env` and is documented in `srcs/.env.example`.

Passwords belong in the files under `srcs/secrets/` and are mounted by Compose into `/run/secrets/...`.

Do not place passwords in Dockerfiles, committed environment files or source code.

## Build

From the repository root:

```bash
make up
```

Equivalent Compose operations use:

```bash
docker compose -f srcs/docker-compose.yml --env-file srcs/.env
```

## Stop

```bash
make down
```

## Rebuild from scratch

```bash
make re
```

This is destructive because the current Makefile performs a full cleanup before rebuilding.

## Debugging

Validate the Compose configuration:

```bash
docker compose -f srcs/docker-compose.yml --env-file srcs/.env config
```

Inspect services:

```bash
docker ps
```

Inspect logs:

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

Validate NGINX configuration:

```bash
docker exec nginx nginx -t
```

Validate WordPress installation:

```bash
docker exec wordpress wp --allow-root --path=/var/www/html core is-installed
```

Test HTTPS locally after domain resolution is configured:

```bash
curl -kI https://vfidelis.42.fr
```

## Development workflow

When modifying a service, rebuild the corresponding image or restart the stack through Compose. Keep service-specific files inside the relevant directory under `srcs/requirements/`.

Before merging changes, verify that:

- all three containers remain running;
- only port `443` is published;
- WordPress can reach MariaDB;
- NGINX can reach PHP-FPM;
- data survives container recreation;
- secret files are not tracked by Git.
