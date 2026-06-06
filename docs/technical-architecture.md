# Technical Architecture

This document defines the first implementation target for Pocket Automations.

## Goals

- Provide a low-friction Ubuntu deployment path for new Pocket Network providers.
- Support both single-node and redundant production architectures.
- Deploy the infrastructure required by Igniter, HA RelayMiner, and Pocket Network chain connectivity.
- Keep staking lifecycle operations inside Igniter rather than duplicating them in Ansible.
- Produce inventories and documentation that novice operators can complete safely.

## Non-Goals

- Ansible does not replace Igniter for supplier staking.
- Ansible does not operate user wallets or delegator wallets.
- Ansible does not run backend blockchain nodes for every possible service by default.
- Ansible does not expose Provider admin UI publicly by default.
- Ansible does not use deprecated Pocket documentation as a source of truth.

## Component Model

### Igniter Provider

Provider is the mandatory operator control plane. It manages staking workflows, supplier lifecycle, keys, relay miner records, address groups, services, delegators, and revenue share policy.

Provider services:

- `provider-migration`
- `provider-web`
- `provider-workflows`

Provider dependencies:

- PostgreSQL
- Temporal
- Pocket RPC endpoint
- Pocket chain identity settings
- Secure app and encryption secrets

### Igniter Middleman

Middleman is optional. It is the delegator-facing application for staking, unstaking, supplier import, portfolio tracking, and reward visibility.

Middleman services:

- `middleman-migration`
- `middleman-web`
- `middleman-workflows`

Middleman dependencies:

- PostgreSQL
- Temporal
- Pocket RPC endpoint
- Provider governance discovery
- Optional market data configuration

### HA RelayMiner

HA RelayMiner is the default relay serving implementation.

Relayer responsibilities:

- Accept relay traffic.
- Validate and sign responses.
- Forward traffic to configured backend nodes.
- Publish relay data to Redis streams.
- Expose health and metrics endpoints.

Miner responsibilities:

- Consume relays from Redis.
- Build session state.
- Coordinate leader election.
- Submit claims and proofs.
- Expose mining metrics.

Redis responsibilities:

- Shared relay streams.
- Session state.
- Leader election.
- Cache and coordination data.

Redis must be version 8.2 or newer for HA RelayMiner support.

### pocketd

`pocketd` remains required for CLI operations, validation, account inspection, and troubleshooting. It should be installed on operator/admin hosts and optionally on relay infrastructure hosts when required.

The standard `pocketd relayminer` is legacy-only in this project. New deployments should use HA RelayMiner.

### Backend Service Nodes

Backend service nodes are the blockchain or API nodes that relayers proxy requests to. Operators are responsible for running, syncing, securing, and monitoring these nodes.

Ansible should validate backend reachability and render HA RelayMiner backend configuration, but it should not assume that every service backend can be installed automatically.

## Architecture Profiles

### Profile 1: All-In-One Lab

Single Ubuntu host running:

- Igniter Provider
- PostgreSQL
- Temporal
- Redis
- HA RelayMiner relayer
- HA RelayMiner miner
- Reverse proxy

Use for testnet, demos, and operator onboarding. Not recommended for production.

### Profile 2: Production Single Host

Single Ubuntu host running Provider, Redis, relayer, miner, and reverse proxy. PostgreSQL and Temporal may be local or managed.

Use for small operators that need a minimal production path but do not require high availability.

### Profile 3: Recommended Production

Separate hosts or managed services for:

- Provider
- PostgreSQL
- Temporal
- Redis
- Relayer nodes
- Miner nodes
- Backend service nodes
- Reverse proxy or load balancer

Use for production operators who want clear failure domains and room to scale.

### Profile 4: HA Relay Mining

Multiple stateless relayers behind a load balancer, multiple miners using Redis coordination, and Redis deployed as a managed service, Sentinel deployment, or future cluster-compatible deployment.

Use for high-volume suppliers, multiple services, or uptime-sensitive providers.

### Profile 5: Provider Plus Public Middleman

Provider remains private or partially exposed through an API allowlist. Middleman is public and serves delegators.

Use for operators that want a public staking portal.

## Inventory Design

The inventory should separate infrastructure by role rather than assuming one host.

Suggested groups:

- `provider_hosts`
- `middleman_hosts`
- `postgres_hosts`
- `temporal_hosts`
- `redis_hosts`
- `relay_relayers`
- `relay_miners`
- `reverse_proxy_hosts`
- `pocket_cli_hosts`

Important global variables:

- `pocket_network`: `main`, `beta`, or `local`
- `pocket_chain_id`: derived from `pocket_network` unless overridden
- `pocket_rpc_url`
- `pocket_grpc_address`
- `provider_domain`
- `provider_public_api_domain`
- `middleman_domain`
- `redis_url`
- `igniter_provider_enabled`
- `igniter_middleman_enabled`
- `ha_relayminer_enabled`

For beta, current documentation maps `--network=beta` to `pocket-lego-testnet`.

## Ansible Roles

Initial role set:

- `common`: Ubuntu packages, users, directories, system limits.
- `docker`: Docker Engine and Compose plugin.
- `pocketd`: `pocketd` installation and CLI validation.
- `redis`: Redis 8.2+ deployment or external Redis validation.
- `ha_relayminer`: relayer and miner configuration, service deployment, health checks.
- `igniter_dependencies`: PostgreSQL and Temporal deployment or validation.
- `igniter_provider`: Provider environment, compose deployment, health checks.
- `igniter_middleman`: Middleman environment, compose deployment, health checks.
- `reverse_proxy`: TLS, Provider allowlist, Middleman public routing, relayer routing.
- `validation`: end-to-end readiness checks.
- `monitoring`: optional Prometheus scrape targets and dashboard guidance.

## Ports

Default ports to model in firewall and reverse proxy tasks:

- `26656/tcp`: Pocket full node P2P.
- `26657/tcp`: CometBFT RPC.
- `9090/tcp`: Pocket gRPC or HA RelayMiner relayer metrics depending on host role.
- `1317/tcp`: REST API.
- `6379/tcp`: Redis, internal only.
- `8080/tcp`: HA RelayMiner relay ingress.
- `8081/tcp`: HA RelayMiner health.
- `9091/tcp`: Prometheus, localhost or private network only.
- `9092/tcp`: HA RelayMiner miner metrics.
- `3002/tcp`: Grafana, localhost/private by default or public only behind authenticated reverse proxy.
- `6060/tcp`: pprof, disabled or localhost-only in production.

## Security Principles

- Provider admin UI is private by default.
- Provider public API exposure is allowlist-only when Middleman needs it.
- Redis is never exposed publicly.
- Temporal UI is never exposed publicly without authentication.
- Secrets are generated with secure permissions and not committed.
- TLS is required for public Provider API, Middleman, and relay endpoints.
- Grafana may be exposed publicly only with reverse proxy authentication.
- Backend service credentials are treated as secrets.
- The operator key may be online for relay operations, but owner custody should remain separate for production.

## Validation Strategy

Validation should be a first-class playbook, not a footnote.

Required checks:

- Ubuntu version support.
- Docker service health.
- Redis version and connectivity.
- HA RelayMiner relayer health endpoint.
- HA RelayMiner miner metrics endpoint.
- Backend service health probes.
- Provider health and bootstrap endpoint.
- Provider workflow worker status.
- Middleman health when enabled.
- Pocket RPC and gRPC reachability.
- Chain ID and network mapping.
- Public DNS resolves to expected hosts.
- Firewall does not expose internal-only ports.

## Staking Workflow Integration

After infrastructure is deployed, the operator completes staking through Igniter Provider:

1. Access Provider bootstrap wizard.
2. Configure blockchain settings.
3. Configure provider identity.
4. Configure regions.
5. Register relay miners and public relay URLs.
6. Select services.
7. Create address groups and revenue share policy.
8. Configure delegator relationships and optional Middleman access.
9. Import supplier operator keys.
10. Use Provider workflows to stake suppliers and reconcile on-chain state.

Ansible should generate a post-deploy report that lists the exact values the operator needs for these steps.
