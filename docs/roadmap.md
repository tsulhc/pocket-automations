# Implementation Roadmap

This roadmap is organized into granular implementation phases that can become separate commits and pull requests.

## Phase 0: Project Foundation

Deliverables:

- Repository README.
- Technical architecture documentation.
- Igniter role documentation.
- Roadmap.
- `ansible.cfg` baseline.
- `requirements.yml` for Ansible collections.
- Initial inventory examples.

Acceptance criteria:

- Documentation states that Igniter owns staking workflows.
- Ubuntu is documented as the default OS target.
- Official Pocket documentation is documented as the source of truth.

## Phase 1: Inventory Model

Deliverables:

- `inventories/all-in-one-lab/hosts.yml`
- `inventories/production-single-host/hosts.yml`
- `inventories/production-ha/hosts.yml`
- `inventories/custom/hosts.yml`
- Group variable examples for Provider, Middleman, Redis, HA RelayMiner, and Pocket network settings.

Acceptance criteria:

- A novice can fill the all-in-one inventory without understanding every internal role.
- Advanced users can split roles across hosts.
- Sensitive values are represented as placeholders and documented for Ansible Vault or external secret managers.

## Phase 2: Ubuntu Common Role

Deliverables:

- `roles/common`
- Base packages.
- Dedicated service users.
- Directory layout.
- System limits for relay workloads.
- Firewall prerequisites.

Acceptance criteria:

- Role runs idempotently on supported Ubuntu hosts.
- Role does not modify unrelated host state beyond documented dependencies.

## Phase 3: Docker Role

Deliverables:

- `roles/docker`
- Docker Engine installation for Ubuntu.
- Docker Compose plugin installation.
- Service enablement and validation.

Acceptance criteria:

- `docker compose version` succeeds after the role runs.
- Existing Docker installations are not downgraded unexpectedly.

## Phase 4: pocketd Role

Deliverables:

- `roles/pocketd`
- Install or upgrade `pocketd`.
- Support configurable version tags.
- Validate `pocketd version`.
- Configure network defaults for `main`, `beta`, and `local`.

Acceptance criteria:

- `pocketd` is available on configured hosts.
- Beta network maps to the current documented chain ID.
- Role does not create wallets by default.

## Phase 5: Igniter Dependencies Role

Deliverables:

- `roles/igniter_dependencies`
- PostgreSQL deployment or external endpoint validation.
- Temporal deployment or external endpoint validation.
- Secure local compose configuration for lab and single-host profiles.

Acceptance criteria:

- Dependencies start before Provider or Middleman.
- Temporal UI is not publicly exposed by default.
- PostgreSQL credentials are not committed or printed in normal logs.

## Phase 6: Igniter Provider Role

Deliverables:

- `roles/igniter_provider`
- Provider compose deployment.
- Environment file rendering.
- Secret generation support.
- Migration, web, and workflow service orchestration.
- Provider health validation.
- Post-deploy bootstrap report.

Acceptance criteria:

- Provider starts successfully in the all-in-one profile.
- Provider bootstrap endpoint is reachable.
- Operator receives a generated summary of values needed for the bootstrap wizard.
- Role clearly documents that staking continues inside Igniter.

## Phase 7: Redis Role

Deliverables:

- `roles/redis`
- Redis 8.2+ deployment for Ubuntu or Docker.
- External Redis validation mode.
- Persistence and no-eviction defaults.
- Internal-only bind defaults.

Acceptance criteria:

- Redis reports version 8.2 or newer.
- Redis is not exposed on public interfaces by default.
- Persistence is enabled unless explicitly disabled for lab use.

## Phase 8: HA RelayMiner Role

Deliverables:

- `roles/ha_relayminer`
- Relayer configuration rendering.
- Miner configuration rendering.
- Service backend model for JSON-RPC, WebSocket, REST, gRPC, and CometBFT.
- Docker Compose or systemd deployment path, selected by variable.
- Health and metrics validation.

Acceptance criteria:

- Relayer health endpoint responds.
- Miner metrics endpoint responds when miner role is enabled.
- Backend services are checked from relayer hosts.
- Redis connection is validated before service start.

## Phase 9: Reverse Proxy Role

Deliverables:

- `roles/reverse_proxy`
- TLS support.
- Public relay routing.
- Provider private admin routing.
- Provider public API allowlist for Middleman.
- Middleman public routing.

Acceptance criteria:

- Provider admin UI is not publicly exposed by default.
- Provider API allowlist is enforced when public Provider API is enabled.
- Redis, Temporal, PostgreSQL, and pprof ports remain private.

## Phase 10: Igniter Middleman Role

Deliverables:

- `roles/igniter_middleman`
- Optional Middleman compose deployment.
- Environment file rendering.
- Migration, web, and workflow service orchestration.
- Middleman health validation.

Acceptance criteria:

- Middleman can be enabled or disabled with a single inventory variable.
- Public URL and Provider discovery settings are validated.
- Provider API connectivity is validated when Provider integration is configured.

## Phase 11: Validation Playbook

Deliverables:

- `playbooks/validate.yml`
- Infrastructure validation report.
- Pocket chain connectivity checks.
- Igniter readiness checks.
- HA RelayMiner readiness checks.
- Backend service checks.
- Security exposure checks.

Acceptance criteria:

- Validation can run after any deployment profile.
- Failures are actionable for novice operators.
- The report distinguishes infrastructure problems from Igniter bootstrap tasks.

## Phase 12: Beginner Experience

Deliverables:

- Guided all-in-one inventory.
- Beginner documentation.
- Post-deploy checklist.
- Troubleshooting guide.

Acceptance criteria:

- A novice operator can complete infrastructure deployment with a small number of edited variables.
- Remaining manual steps are explicitly tied to Igniter UI workflows.

## Phase 13: Production Hardening

Deliverables:

- Monitoring role or Prometheus scrape examples.
- Backup guidance for PostgreSQL, Redis, and Igniter state.
- Secret rotation guidance.
- Upgrade playbooks.
- Disaster recovery guidance.

Acceptance criteria:

- Operators have a documented path for backup, restore, upgrade, and incident response.
- Production deployment avoids demo-only defaults.

## Commit Strategy

Use granular commits by logical unit. Suggested order:

1. `docs: add architecture and igniter staking boundary`
2. `docs: add implementation roadmap`
3. `chore: add ansible project scaffold`
4. `feat: add ubuntu common role`
5. `feat: add docker role`
6. `feat: add pocketd role`
7. `feat: add igniter provider role`
8. `feat: add redis role`
9. `feat: add ha relayminer role`
10. `feat: add reverse proxy role`
11. `feat: add middleman role`
12. `feat: add validation playbook`

Each commit should leave the repository in a coherent state with documentation matching the implemented behavior.
