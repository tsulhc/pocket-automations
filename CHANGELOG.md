# Changelog

All notable changes to Pocket Automations will be documented in this file.

## Unreleased

### Changed

- HA RelayMiner now pulls the upstream GHCR image by default instead of building from source.
- Ubuntu 26.04 is now included in the supported target matrix, using Docker's Ubuntu `noble` repository suite until a dedicated Docker suite exists.

### Fixed

- Self-hosted Igniter PostgreSQL now uses an Ansible-managed configuration suitable for smaller VMs.
- Igniter dependency databases are reconciled after startup so failed first boots do not leave missing Provider/Middleman databases.
- Igniter repository checkouts tolerate Ansible-managed compose/config files in the upstream tree.
- Validation now warns when Redis or HA RelayMiner raw health/metrics binds are public.

### Added

- Full Ubuntu Ansible deployment flow for Igniter Provider, optional Middleman, HA RelayMiner, Redis, PostgreSQL, Temporal, Caddy, Prometheus, and Grafana.
- Guided setup wizard for production single-host inventories.
- Non-interactive wizard mode using bash-compatible config files.
- Validation playbook with PASS/WARN/FAIL reporting.
- Upgrade playbook for component-focused day-2 operations.
- Production hardening, secret rotation, monitoring, troubleshooting, and beginner documentation.
- GitHub Actions checks for Ansible syntax, inventory parsing, shell syntax, and shellcheck.

### Scope

- Backup/restore and disaster recovery are explicitly out of scope.
- Supplier staking and lifecycle operations remain owned by Igniter, not Ansible.

### Validated

- Single-host Ubuntu 24.04 deployment flow validated on a real VM.
- Monitoring and public Grafana routing with Caddy basic auth validated on a real VM.
- Four-VM Ubuntu 26.04 public-IP HA smoke test validated proxy, Provider/dependencies, Redis, relayer, monitoring, and public Grafana authentication.
