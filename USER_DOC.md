# User Documentation

## Overview

This project runs a WordPress website with NGINX, PHP-FPM and MariaDB in separate Docker containers.

The only externally exposed service is NGINX on HTTPS port `443`.

## Prerequisites

Before starting the project, make sure Docker and Docker Compose are installed and that the repository contains a local `srcs/.env` file.

Create it from the example when necessary:

```bash
cp srcs/.env.example srcs/.env
```

## Required secrets

Create the following local files:

```text
srcs/secrets/db_password.txt
srcs/secrets/db_root_password.txt
srcs/secrets/wp_password.txt
srcs/secrets/wp_root_password.txt
```

Each file must contain only the corresponding password.

Recommended permissions:

```bash
chmod 600 srcs/secrets/*.txt
```

These files must not be committed to Git.

## Start the infrastructure

From the repository root:

```bash
make
```

or:

```bash
make up
```

The Makefile creates the persistent data directories and starts the Compose stack.

## Access WordPress

The configured domain is:

```text
https://vfidelis.42.fr
```

The domain must resolve to the IP address of the virtual machine from the computer where the browser is running.

Because the project uses a self-signed certificate, the browser may display a certificate warning during local development.

## WordPress administration

The WordPress administrator account is configured through the public variables in `srcs/.env` and the administrator password secret.

The project also creates a second non-administrator WordPress user.

## Stop the infrastructure

```bash
make down
```

This stops and removes the containers while keeping persistent data.

## View logs

```bash
make logs
```

You can also inspect an individual service:

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

## Check running containers

```bash
docker ps
```

Expected services:

```text
nginx
wordpress
mariadb
```

Only NGINX should publish port `443` to the host.

## Reset the project

```bash
make fclean
```

This command performs a destructive cleanup, including persistent project data. Do not use it when you need to preserve the current WordPress installation or database.

## Persistent data

The project keeps database and WordPress files under:

```text
/home/vfidelis/data/mariadb
/home/vfidelis/data/wordpress
```

Destroying and recreating a container does not remove these files unless the volumes/data directories are explicitly deleted.
