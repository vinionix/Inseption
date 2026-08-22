*This project has been created as part of the 42 curriculum by vfidelis.*

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

### Logs and status

```bash
make logs
make status
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

The configured site is:

```text
https://vfidelis.42.fr
```

The WordPress administration panel is:

```text
https://vfidelis.42.fr/wp-admin
```

The machine opening the site must resolve `vfidelis.42.fr` to the IP address of the Inception virtual machine. Because the project generates a self-signed TLS certificate, a browser warning is expected until the certificate is explicitly trusted.

## Project description

### Virtual Machines vs Docker

| Virtual Machine | Docker container |
| --- | --- |
| Virtualizes a complete operating system | Isolates processes while sharing the host kernel |
| Requires more memory and disk space | Usually lighter and faster to start |
| Includes its own kernel | Uses the VM/host kernel |
| Useful for strong OS-level isolation | Useful for reproducible service isolation |

In this project, the VM is the isolated Linux host and Docker separates the individual application services inside that VM.

### Secrets vs Environment Variables

| Environment variable | Docker secret |
| --- | --- |
| Suitable for non-sensitive configuration | Intended for sensitive values such as passwords |
| Available directly in a process environment | Mounted as a file under `/run/secrets` |
| Easy to expose accidentally in debugging/output | Keeps credentials separate from public configuration |

This repository uses `srcs/.env` for public configuration and local secret files for passwords. Real secret files must not be committed.

### Docker Network vs Host Network

| Docker bridge network | Host network |
| --- | --- |
| Containers have isolated network namespaces | Containers share the host network stack |
| Services can resolve each other by Compose service name | Services use the host interfaces directly |
| Ports are exposed only when explicitly published | Container services are directly tied to host networking |
| Provides better service isolation for this architecture | Removes much of the intended container network isolation |

The project uses the `inception` bridge network. NGINX reaches PHP-FPM through `wordpress:9000`, while WordPress reaches MariaDB through `mariadb:3306`. Host networking and Docker links are not used.

### Docker Volumes vs Bind Mounts

| Docker named volume | Bind mount |
| --- | --- |
| Has a Docker-managed volume identity | Maps a host filesystem path directly |
| Visible through Docker volume commands | Managed primarily as a host path |
| Has an independent container lifecycle | Exists independently as a normal host directory |
| Useful for persistent container data | Useful when direct host-path control is needed |

This project declares named volumes with the local driver and uses the driver's `device` option so data is physically stored under the required host paths:

```text
/home/vfidelis/data/mariadb
/home/vfidelis/data/wordpress
```

MariaDB mounts its volume at `/var/lib/mysql`. WordPress mounts its volume at `/var/www/html`, and NGINX mounts the same WordPress volume read-only so it can serve static files.

### PID 1 and foreground processes

Each service ends its initialization by replacing the shell with the real server process using `exec`:

- MariaDB runs `mariadbd` in foreground.
- WordPress runs PHP-FPM in foreground.
- NGINX runs with `daemon off;`.

This lets Docker manage signals and container lifecycle correctly.

## Documentation

- [`USER_DOC.md`](USER_DOC.md): how to start, stop, access and operate the project.
- [`DEV_DOC.md`](DEV_DOC.md): architecture, setup, build details, volumes, networking, debugging and maintenance.
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
