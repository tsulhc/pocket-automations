# Pocket Automations

Ansible automation for deploying Pocket Network provider infrastructure on Ubuntu.

The project targets operators who need a guided path from a small single-node setup to redundant production deployments. The default stack is:

- `pocketd` from `poktroll` for Pocket Network CLI and chain interaction.
- `pocket-relay-miner` for production relay serving, split into stateless relayers and stateful miners coordinated through Redis.
- Igniter Provider as the mandatory staking operations platform.
- Igniter Middleman as an optional delegator-facing staking application.

## Product Boundary

Igniter owns supplier staking and staking lifecycle operations. Ansible does not submit supplier staking, service update, or unstaking transactions directly. Ansible prepares the infrastructure that Igniter needs, validates readiness, deploys dependencies, configures services, and documents any manual or UI-driven steps that remain.

## Default Assumptions

- Ubuntu is the default operating system target.
- Documentation and code are written in English.
- HA RelayMiner is the default relay-mining implementation for new deployments.
- Standard `pocketd relayminer` support is legacy-only and should not be the default path.
- PostgreSQL, Temporal, Redis, reverse proxy, and service endpoints must be secured before production use.

## Documentation

- [Technical Architecture](docs/technical-architecture.md)
- [Igniter Role](docs/igniter-role.md)
- [Implementation Roadmap](docs/roadmap.md)

## Source Of Truth

Use the current Pocket Network documentation at <https://docs.pocket.network/>. Older `dev.poktroll.com` documentation is deprecated for this project unless explicitly requested.
