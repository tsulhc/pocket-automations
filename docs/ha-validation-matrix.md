# HA Validation Matrix

This matrix defines what must be tested before claiming a topology is production-validated.

Backup, restore, and disaster recovery are intentionally out of scope.

## Topologies

| Topology | Purpose | Required Before Production Claim |
| --- | --- | --- |
| Single host | Beginner production baseline | Already validated for the core flow; miner requires real supplier keys. |
| Split proxy + app | Validate Caddy on a public edge host | Pending. |
| Split monitoring | Validate central Prometheus/Grafana scraping private targets | Pending. |
| Split relayer + miner | Validate HA RelayMiner component separation | Pending. |
| Multi-relayer | Validate public relay traffic distribution | Pending. |
| External Redis | Validate operator-managed Redis endpoint mode | Pending. |
| Full HA | Validate proxy, Provider, RelayMiner, Redis, and monitoring across separate hosts | Pending. |

## Real Validation Evidence

### 2026-06-08: Four-VM Public-IP HA Smoke Test

Validated with four clean Ubuntu 26.04 VMs using public `sslip.io` domains.

| Host | Groups | Result |
| --- | --- | --- |
| `proxy-01` | `reverse_proxy_hosts`, `monitoring_hosts` | PASS: Caddy relay route, public Grafana basic auth, Prometheus, Grafana, dashboard provisioning. |
| `provider-01` | `provider_hosts`, `postgres_hosts`, `temporal_hosts`, `pocket_cli_hosts` | PASS: Dockerized PostgreSQL/Temporal, `pocketd`, Igniter Provider migration/web/workflows. |
| `relay-01` | `relay_relayers` | PASS with WARN: relayer health/metrics and Redis connectivity passed; backend checks were not configured; raw health/metrics were publicly bound in the temporary public-IP topology. |
| `redis-01` | `redis_hosts` | PASS with WARN: Redis connectivity passed; Redis was intentionally bound to `0.0.0.0` for the public-IP-only test and must be private or firewall-restricted in production. |

Validated changes from this run:

- HA RelayMiner now pulls `ghcr.io/pokt-network/pocket-relay-miner:f882c51` by default instead of building from source.
- Ubuntu 26.04 works with the Docker Ubuntu `noble` repository suite override.
- Self-hosted Igniter PostgreSQL needs a smaller Ansible-managed `postgresql.conf` on small VMs.
- Igniter dependency databases are reconciled idempotently after startup.
- Igniter repository checkouts must tolerate Ansible-managed files inside the upstream compose tree.
- Validation now warns when Redis, relayer health, or relayer metrics are publicly bound.

Remaining gaps from this run:

- Miner runtime was not validated because that requires real supplier keys and staking lifecycle handled through Igniter.
- Multi-relayer load distribution was not validated.
- Backend readiness checks were intentionally disabled in the temporary inventory.
- Private-network or firewall enforcement was not validated; the public-IP-only test used explicit warnings instead.

## Required Checks

For each topology:

- `ansible-inventory --list` parses the inventory;
- `playbooks/site.yml` completes;
- `playbooks/validate.yml` reports no `FAIL` items;
- public relay TLS endpoint responds;
- relayer health responds at `/health`;
- relayer metrics are scraped by Prometheus;
- miner metrics are scraped when miner hosts are enabled;
- backend checks are configured or warnings are explicitly accepted;
- Provider health is reachable from the deployment network;
- Grafana is private or public with authentication;
- Redis, PostgreSQL, Temporal, Prometheus, raw metrics, and pprof are not publicly exposed.

## Suggested VM Layout

Minimum useful multi-host test:

| Host | Groups |
| --- | --- |
| `proxy-01` | `reverse_proxy_hosts` |
| `provider-01` | `provider_hosts`, `postgres_hosts`, `temporal_hosts`, `pocket_cli_hosts` |
| `relay-01` | `relay_relayers` |
| `miner-01` | `relay_miners`, `redis_hosts` |
| `monitoring-01` | `monitoring_hosts` |

This layout validates private east-west routing without requiring a large fleet.

Reduced public-IP-only test used on 2026-06-08:

| Host | Groups |
| --- | --- |
| `proxy-01` | `reverse_proxy_hosts`, `monitoring_hosts` |
| `provider-01` | `provider_hosts`, `postgres_hosts`, `temporal_hosts`, `pocket_cli_hosts` |
| `relay-01` | `relay_relayers` |
| `redis-01` | `redis_hosts` |

Use this only for smoke testing. Production HA should place Redis, raw metrics, health endpoints, PostgreSQL, Temporal, and Prometheus on a private network or behind firewall rules.

## Evidence To Record

For each real HA run, record:

- date;
- Ubuntu version;
- Ansible version;
- inventory profile used;
- enabled components;
- validation PASS/WARN/FAIL counts;
- known warnings;
- manual Igniter steps still required.

Do not record private keys, app identities, passwords, or raw secret values.
