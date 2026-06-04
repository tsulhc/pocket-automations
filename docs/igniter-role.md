# Igniter Role In The Automation

Igniter is the operational control plane for staking. This project should treat Igniter as the component that owns supplier lifecycle, delegator workflows, provider registration, and staking state transitions.

## What Igniter Does

Igniter is a staking operations platform with two applications:

- **Provider**: the operator-facing application. It manages supplier keys, relay miner records, address groups, services, delegator relationships, revenue share configuration, and supplier lifecycle workflows.
- **Middleman**: the optional delegator-facing application. It lets token holders stake, unstake, import suppliers, track rewards, and manage staking positions without operating infrastructure.

Both applications use PostgreSQL and Temporal workflow workers. PostgreSQL stores application state and, for Provider deployments, encrypted key material. Temporal coordinates long-running workflows such as staking, unstaking, supplier import, remediation, and governance synchronization.

## Staking Boundary

All supplier staking actions must be performed through Igniter workflows.

Ansible must not directly run these commands as part of normal operation:

- `pocketd tx supplier stake-supplier`
- `pocketd tx supplier unstake-supplier`
- `pocketd tx supplier stake-supplier --stake-only`
- `pocketd tx supplier stake-supplier --services-only`

Ansible may still install `pocketd` because operators need it for validation, account inspection, manual troubleshooting, and chain queries. Ansible may also generate reference files or command previews, but these are supporting artifacts rather than the staking execution path.

## Provider Is Mandatory

The Provider application is mandatory for this automation because it is the operator control plane. It should be deployed before the operator attempts to onboard suppliers through Igniter.

Ansible responsibilities for Provider:

- Install Docker and Docker Compose on Ubuntu.
- Deploy or connect to PostgreSQL.
- Deploy or connect to Temporal.
- Generate Provider environment files from inventory variables.
- Generate strong `ENCRYPTION_IV`, `ENCRYPTION_KEY`, and `AUTH_SECRET` values when they are not supplied.
- Configure `POKT_RPC_URL`, `CHAIN_ID`, `BLOCKCHAIN_PROTOCOL`, `OWNER_IDENTITY`, `OWNER_EMAIL`, and `APP_IDENTITY`.
- Start Provider migrations, web service, and workflow worker.
- Validate Provider health and bootstrap availability.
- Document the bootstrap wizard path and required operator decisions.

Ansible must not store generated secrets in Git. Secrets should be supplied through Ansible Vault, external secret managers, or explicitly generated on the target host with secure file permissions.

## Middleman Is Optional

Middleman is optional because not every provider will expose a delegator-facing staking portal. It should be enabled only when the operator wants users or token holders to stake through a web application.

Ansible responsibilities for Middleman:

- Deploy Middleman migration, web, and workflow services.
- Configure PostgreSQL and Temporal settings.
- Configure `OWNER_IDENTITY`, `OWNER_EMAIL`, `APP_IDENTITY`, `APP_URL`, `AUTH_URL`, `CHAIN_ID`, and `POKT_RPC_URL`.
- Configure `PROVIDERS_CDN_URL` or the governance source used to discover providers.
- Optionally configure `COIN_MARKET_CAP_API_KEY` when required by the selected deployment mode.
- Validate Middleman health and bootstrap availability.

## Provider And Middleman Network Boundary

Provider serves an admin UI and APIs. The admin UI must remain private. If Middleman needs to communicate with Provider over the public internet, the reverse proxy must expose only the Provider API paths required by Middleman and block all admin, auth, and web UI paths.

Allowed Provider API paths for Middleman communication:

- `POST /api/suppliers`
- `POST /api/suppliers/stake`
- `POST /api/suppliers/unstaking`
- `POST /api/suppliers/release`
- `POST /api/import-suppliers/request`
- `POST /api/import-suppliers/submit`
- `POST /api/import-suppliers/status`
- `POST /api/status`
- `GET /api/health`
- `GET /api/bootstrap`

Everything else should be blocked from public access unless the operator intentionally exposes it through a VPN, private network, or protected admin endpoint.

## How Igniter Complements Relay Infrastructure

Igniter does not replace the relay-serving stack. It manages the staking and operations workflow around that stack.

The relationship is:

- `pocket-relay-miner` relayers receive relay traffic and forward requests to backend service nodes.
- `pocket-relay-miner` miners submit claims and proofs using the operator identity and Redis-backed relay state.
- Redis stores shared HA RelayMiner state.
- Pocket full node RPC/gRPC endpoints provide chain state and transaction connectivity.
- Igniter Provider manages which suppliers, keys, services, address groups, delegators, and revenue share rules should exist.
- Igniter workflows submit and reconcile staking operations.

## Bootstrap Flow

The Ansible-driven installation should guide operators through this sequence:

1. Provision Ubuntu hosts and common dependencies.
2. Install Docker and Docker Compose.
3. Deploy PostgreSQL and Temporal, or validate external endpoints.
4. Deploy Igniter Provider.
5. Deploy Redis 8.2+ for HA RelayMiner.
6. Deploy HA RelayMiner relayer and miner services.
7. Configure reverse proxy and TLS.
8. Run infrastructure validation.
9. Open the Igniter Provider bootstrap wizard.
10. Use Igniter to import keys, configure regions, relay miners, services, address groups, delegators, and supplier staking.
11. Optionally deploy Middleman and register governance metadata.

## Ansible Validation Around Igniter

The validation role should check:

- Provider web service is reachable on the intended private/admin URL.
- Provider bootstrap endpoint responds.
- Provider workflow worker is running.
- Provider migration completed successfully.
- PostgreSQL connection works.
- Temporal namespace and task queue are available.
- Pocket RPC endpoint is reachable.
- Pocket network setting maps to the expected chain ID.
- HA RelayMiner health endpoint is reachable.
- Redis version is at least 8.2.
- Configured backend service URLs are reachable from relayer hosts.
- Public relay URLs match the values intended for Igniter service configuration.

## Transaction Handling Policy

Because Igniter owns staking, transaction handling in this automation is limited to validation and operator support.

Allowed Ansible transaction-related behavior:

- Query balances.
- Query supplier state.
- Query proof fee parameters.
- Query provider-facing readiness data.
- Render human-readable summaries for the Igniter bootstrap wizard.
- Detect that an operator account has never appeared on-chain and warn that Igniter or the operator must establish the required on-chain identity before production relay serving.

Disallowed default behavior:

- Direct supplier stake submission.
- Direct services-only updates.
- Direct stake-only updates.
- Direct unstake submission.
- Any automated transaction involving production funds without a separate, explicit future design decision.
