# Changelog

All notable changes to Pocket Automations will be documented in this file.

## Unreleased

### Added

- Full Ubuntu Ansible deployment flow for Igniter Provider, optional Middleman, HA RelayMiner, Redis, PostgreSQL, Temporal, Caddy, Prometheus, and Grafana.
- Guided setup wizard for production single-host inventories.
- Non-interactive wizard mode using bash-compatible config files.
- Validation playbook with PASS/WARN/FAIL reporting.
- Upgrade playbook for component-focused day-2 operations.
- Production hardening, secret rotation, monitoring, troubleshooting, and beginner documentation.
- GitHub Actions checks for Ansible syntax, inventory parsing, shell syntax, and shellcheck.

### Changed

- Backup/restore and disaster recovery are explicitly out of scope.
- Supplier staking and lifecycle operations remain owned by Igniter, not Ansible.

### Validated

- Single-host Ubuntu 24.04 deployment flow validated on a real VM.
- Monitoring and public Grafana routing with Caddy basic auth validated on a real VM.
