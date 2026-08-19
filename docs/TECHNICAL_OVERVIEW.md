# Technical Overview — Inseption

## Purpose

This repository is an infrastructure/containerization project based on the 42 Inception-style exercise. The current implementation uses Docker Compose to orchestrate a WordPress service and a MariaDB service with isolated builds, persistent volumes, Docker secrets and a dedicated bridge network.

## Current topology

```text
                inception bridge network
        ┌─────────────────────────────────┐
        │                                 │
        │   WordPress  ───────> MariaDB   │
        │       │                │        │
        └───────┼────────────────┼────────┘
                │                │
        wordpress_data     mariadb_data
          bind volume        bind volume
```

The current `docker-compose.yml` defines two application services:

- `wordpress`
- `mariadb`

Both are built from local requirement directories instead of simply using a preconfigured Compose image definition.

## Configuration and secrets

Runtime configuration is loaded through an `.env` file, while password-like values are referenced through Docker Compose secrets.

The repository contains an `.env.example` and a `srcs/secrets/README.md`; actual password files should remain outside version control.

## Persistence

Two named volumes are configured with local bind mounts:

- `mariadb_data` → database files;
- `wordpress_data` → WordPress application data.

This separates container lifecycle from application data lifecycle: containers can be rebuilt without intentionally discarding the persistent state.

## Networking

Both services join a dedicated bridge network named `inception`. WordPress declares a dependency on MariaDB and communicates with it over the internal Docker network.

The design helps demonstrate service discovery and network isolation inside a Compose application.

## Current limitations

The checked Compose file currently defines WordPress and MariaDB but does not define an Nginx service. If the target is the complete mandatory 42 Inception architecture, the reverse-proxy/TLS layer still needs to be added or documented once implemented.

The volume host paths are also currently tied to `/home/vfidelis/data/...`, so portability requires either matching directories or parameterizing the host path.

## Security notes

- never commit the real `.env` file;
- never commit password files under `srcs/secrets/`;
- use the provided examples/documentation only as templates;
- secrets committed in Git history must be rotated even if later deleted;
- avoid publishing real hostnames or production credentials in this learning repository.

## Validation checklist

A useful local validation includes:

1. build all images from a clean state;
2. bring the Compose stack up;
3. verify MariaDB initializes and remains healthy;
4. verify WordPress reaches the database over the internal network;
5. restart containers and confirm persistent data survives;
6. inspect networks and volumes;
7. confirm secrets are mounted at runtime and not baked into images;
8. tear down and rebuild the stack.

## Portfolio value

This project demonstrates practical infrastructure skills that support backend and AI systems work:

- Docker image construction;
- Docker Compose orchestration;
- service networking;
- persistent storage;
- environment configuration;
- secrets handling;
- operational troubleshooting.
