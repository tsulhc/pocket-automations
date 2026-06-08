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
