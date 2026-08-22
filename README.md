This project has been created as part of the 42 curriculum by vfidelis.

# Inception

## Description

Inception is a system-administration project that builds a small web infrastructure with Docker Compose inside a virtual machine.

The mandatory stack is split into three dedicated containers:

- **NGINX**: the only external entrypoint, exposed on HTTPS port `443` with TLS 1.2 and TLS 1.3.
- **WordPress + PHP-FPM**: the application container, listening internally on port `9000` through FastCGI.
- **MariaDB**: the database container, listening internally on port `3306`.

```text
Browser
   |
   | HTTPS :443
   v
NGINX
   |
   | FastCGI :9000
   v
WordPress + PHP-FPM
   |
   | MariaDB :3306
   v
MariaDB
```

Only NGINX publishes a host port. WordPress and MariaDB communicate exclusively through the private Docker network.

## Instructions

### Prerequisites

Run the project inside the Linux virtual machine used for Inception with Docker Engine, Docker Compose v2 and GNU Make installed.

Create the public environment file from the tracked example when necessary:

```bash
cp srcs/.env.example srcs/.env
```

Create the local secret files:

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

Passwords must remain local and must not be committed to Git.

### Build and start

From the repository root:

```bash
make
```

or:

```bash
make up
```

### Stop

```bash
make down
```

### Logs

```bash
make logs
```

### Validate Compose

```bash
make config
```

### Full reset

```bash
make fclean
```

`fclean` removes the project containers, images, volumes and persistent project data. Use it only when a full reset is intended.

### Access

The configured domain is:

```text
https://vfidelis.42.fr
```

The machine opening the site must resolve `vfidelis.42.fr` to the IP address of the Inception virtual machine. Because the project generates a self-signed TLS certificate, a browser warning is expected until the certificate is explicitly trusted.

## Project description

### Docker and the virtual machine

The virtual machine provides an isolated Linux host. Docker then isolates each project service at process level while sharing the VM kernel. This is lighter than creating one complete virtual machine per service and makes the infrastructure reproducible from Dockerfiles and Compose.

### Docker network vs host network

The project uses a dedicated bridge network named `inception`.

With a Docker bridge network, containers receive private addresses and resolve other services by name. For example, NGINX reaches PHP-FPM through `wordpress:9000`, and WordPress reaches the database through `mariadb:3306`.

Host networking would remove that network isolation and is not used. Only NGINX explicitly publishes port `443`.

### Docker volumes vs bind mounts

A Docker named volume has a Docker-managed identity and lifecycle. A bind mount maps a host path directly into a container.

This project declares named volumes with the local driver and uses the driver's `device` option so the persistent data is physically stored at the required host locations:

```text
/home/vfidelis/data/mariadb
/home/vfidelis/data/wordpress
```

The MariaDB volume is mounted at `/var/lib/mysql`. The WordPress volume is mounted at `/var/www/html` and is also mounted read-only in NGINX so NGINX can serve static files.

### Secrets vs environment variables

Public configuration belongs in `srcs/.env` and is documented in `srcs/.env.example`.

Passwords are stored in local secret files and mounted by Docker Compose under `/run/secrets/...`. They are not embedded in Dockerfiles or committed environment templates.

### PID 1 and foreground processes

Each service ends its initialization by replacing the shell with the real server process using `exec`:

- MariaDB runs `mariadbd` in foreground.
- WordPress runs PHP-FPM in foreground.
- NGINX runs with `daemon off;`.

This keeps the actual service as PID 1 so Docker can manage signals and container lifecycle correctly.

## Documentation

- [`USER_DOC.md`](USER_DOC.md): how to start, stop, access and operate the project.
- [`DEV_DOC.md`](DEV_DOC.md): architecture, build details, volumes, networking, debugging and maintenance.
- [`EVALUATION.md`](EVALUATION.md): final local checks before peer evaluation.

## Resources

References used while developing the project include:

- Docker Engine documentation
- Docker Compose specification
- Dockerfile best practices
- NGINX documentation
- OpenSSL documentation
- PHP-FPM documentation
- WordPress and WP-CLI documentation
- MariaDB Server documentation

### AI usage

AI assistance was used to explain Docker, networking, FastCGI, PHP-FPM, TLS and PID 1 concepts; review configuration files; identify integration and security issues; draft repetitive infrastructure boilerplate; and prepare project documentation and evaluation checks.

The generated material was adapted to this repository and should be reviewed together with the running infrastructure before evaluation.
