# Developer Documentation

## Prerequisites

The project is designed to run inside the Inception Linux virtual machine.

Required tools:

- Docker Engine
- Docker Compose v2
- GNU Make
- a shell environment capable of creating the local secret files

## Project structure

```text
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── EVALUATION.md
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

Each mandatory service is built from its own Dockerfile. Application service images are not pulled directly.

## Setup from scratch

Clone the repository inside the VM and enter the project directory.

Create the public environment file:

```bash
cp srcs/.env.example srcs/.env
```

Review the values in `srcs/.env`, especially the domain, database name, usernames and WordPress emails.

Create the required secrets:

```text
srcs/secrets/db_password.txt
srcs/secrets/db_root_password.txt
srcs/secrets/wp_password.txt
srcs/secrets/wp_root_password.txt
```

Set restrictive permissions:

```bash
chmod 600 srcs/secrets/*.txt
```

Do not commit the real secret files.

## Build and launch

From the repository root:

```bash
make up
```

The Makefile creates:

```text
/home/vfidelis/data/mariadb
/home/vfidelis/data/wordpress
```

and then executes Docker Compose using:

```bash
docker compose -f srcs/docker-compose.yml --env-file srcs/.env
```

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

NGINX is the only service with a host-published port. WordPress and MariaDB remain reachable only through the internal Docker network.

## MariaDB

The MariaDB image is based on Debian and installs MariaDB with the package manager.

The startup script:

1. prepares MariaDB runtime directories;
2. validates and reads database secrets from `/run/secrets`;
3. initializes the data directory only when necessary;
4. starts a temporary socket-only MariaDB instance;
5. creates the WordPress database and database user;
6. configures the local root password;
7. removes anonymous users and the test database;
8. shuts down the temporary instance;
9. starts `mariadbd` in foreground as PID 1.

MariaDB listens on port `3306` inside the Docker network and does not publish that port to the host.

## WordPress and PHP-FPM

The WordPress image installs PHP, PHP-FPM, the required PHP extensions, MariaDB client utilities and WP-CLI.

Its startup script waits for MariaDB, downloads WordPress when necessary, creates `wp-config.php`, installs the site and creates the configured users.

PHP-FPM listens on:

```text
0.0.0.0:9000
```

This makes FastCGI available to NGINX over the private Docker network without publishing port `9000` to the host.

The final process is PHP-FPM in foreground mode.

## NGINX

NGINX is the only external entrypoint.

Its startup script creates a self-signed certificate when needed and then starts NGINX in foreground mode.

The NGINX configuration:

- listens on port `443` with SSL enabled;
- allows TLS 1.2 and TLS 1.3;
- serves static WordPress files from `/var/www/html`;
- forwards PHP requests to `wordpress:9000` using FastCGI;
- writes access/error logs to container stdout/stderr.

## Docker network

All mandatory services join the `inception` bridge network.

Compose service names provide internal DNS resolution:

```text
wordpress:9000
mariadb:3306
```

No fixed container IPs, host networking or Docker links are required.

## Volumes and persistent storage

Two named volumes are declared in Compose:

- MariaDB data -> `/var/lib/mysql`
- WordPress files -> `/var/www/html`

The local volume driver points their physical storage to:

```text
/home/vfidelis/data/mariadb
/home/vfidelis/data/wordpress
```

The WordPress volume is mounted read-write in the WordPress container and read-only in NGINX.

Container deletion therefore does not automatically delete the application data.

## Environment and secrets

`srcs/.env` contains non-secret configuration. `srcs/.env.example` documents the expected variables.

Passwords are read from Docker secrets mounted under `/run/secrets`. Passwords must not be embedded in Dockerfiles, the Compose file or tracked environment templates.

## Useful lifecycle commands

Build/start:

```bash
make up
```

Stop while preserving data:

```bash
make down
```

Show status:

```bash
make status
```

Follow logs:

```bash
make logs
```

Validate Compose:

```bash
make config
```

Full destructive rebuild:

```bash
make re
```

## Useful Docker commands

Containers:

```bash
docker ps
docker logs nginx
docker logs wordpress
docker logs mariadb
```

Volumes:

```bash
docker volume ls
docker volume inspect srcs_mariadb_data
docker volume inspect srcs_wordpress_data
```

Network:

```bash
docker network ls
docker network inspect srcs_inception
```

NGINX validation:

```bash
docker exec nginx nginx -t
```

WordPress validation:

```bash
docker exec wordpress wp --allow-root --path=/var/www/html core is-installed
```

MariaDB validation:

```bash
docker exec mariadb sh -c 'mariadb -u root -p"$(cat /run/secrets/db_root_password)" -e "SHOW DATABASES;"'
```

## Domain configuration

`vfidelis.42.fr` must resolve to the VM IP from the machine used to access the site. This is host/VM configuration rather than a Docker image responsibility.

After domain resolution is configured:

```bash
curl -kI https://vfidelis.42.fr
```

## Development workflow

Keep each service implementation under `srcs/requirements/<service>/`. Rebuild the affected image after changing a Dockerfile, startup script or application configuration.

Before considering a change complete, verify that:

- all three containers remain running;
- only port `443` is published;
- NGINX reaches PHP-FPM;
- WordPress reaches MariaDB;
- data survives container recreation;
- real secret files remain untracked;
- the clean-start checks in `EVALUATION.md` pass.
