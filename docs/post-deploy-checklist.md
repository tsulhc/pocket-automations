# Post-Deploy Checklist

Use this checklist after `playbooks/site.yml` completes.

## Validation Report

- Run `ansible-playbook -i <inventory> playbooks/validate.yml`.
- Open `/var/lib/pocket-automations/validation-report.md` on each target host.
- Fix every `FAIL` item.
- Review every `WARN` item.

## Infrastructure

- Docker is active.
- Docker Compose plugin is available.
- PostgreSQL is running or external PostgreSQL is reachable.
- Temporal is running or external Temporal is reachable.
- Redis is reachable and not publicly exposed by default.
- Caddy is running when reverse proxy is enabled.

## Pocket Connectivity

- Pocket RPC URL is reachable.
- Pocket gRPC endpoint is reachable.
- Chain ID matches the selected network.
- `beta` maps to `pocket-lego-testnet`.

## Igniter Provider

- Provider health endpoint is reachable.
- Provider bootstrap report exists.
- Provider UI bootstrap has been completed.
- Provider `APP_IDENTITY` came from a real secret source, not a demo placeholder.

## HA RelayMiner

- Relayer health endpoint responds at `/health`.
- Relayer metrics endpoint responds.
- Miner metrics endpoint responds when miner is enabled.
- Supplier/operator keys are present at the configured key source.
- Backend checks pass from the relayer host.
- Redis URL is correct.

## Reverse Proxy

- Public relay domain resolves to the intended VM or load balancer.
- TLS certificate is issued successfully.
- Relay traffic routes to HA RelayMiner.
- Provider admin UI is not publicly exposed by default.
- Redis, PostgreSQL, Temporal, metrics, and pprof are not intentionally proxied.

## Igniter Lifecycle

- Supplier configuration is complete in Igniter Provider.
- Service definitions are correct.
- Relay miner URLs match public relay domains.
- Supplier staking is completed in Igniter.
- Address groups and delegator settings are correct, if used.

## Reward Readiness

The deployment is reward-ready only when all of these are true:

- validation has no `FAIL` items;
- miner is enabled and healthy;
- supplier keys are available to HA RelayMiner;
- Igniter Provider bootstrap is complete;
- supplier lifecycle configuration is complete in Igniter;
- backend services are reachable and healthy;
- public relay ingress works over TLS.
