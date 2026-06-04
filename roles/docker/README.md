# docker

Installs Docker Engine and the Docker Compose plugin on Ubuntu.

The role uses Docker's official Ubuntu apt repository and validates both `docker version` and `docker compose version` after installation.

By default no login users are added to the `docker` group. Set `docker_users` explicitly when a host requires non-root Docker access.
