# Production Security Hardening

This guide covers security hardening that is in scope for the automation. Backup, restore, and disaster recovery are intentionally out of scope.

## Public Surface

Only these services should normally be public:

- Caddy on `80/tcp` and `443/tcp`;
- public relay domain routed to HA RelayMiner;
- optional Middleman domain;
- optional Provider public API allowlist for Middleman;
- optional Grafana domain with basic authentication.

Do not expose:

- Redis;
- PostgreSQL;
- Temporal;
- Prometheus;
- raw RelayMiner metrics ports;
- pprof;
- Provider admin UI unless protected by a private network or explicit access controls.

## SSH

Recommended host policy:

- use key-based authentication only;
- disable root login after bootstrap if operationally possible;
- keep `ansible_user` as a sudo-capable non-root user;
- restrict SSH by firewall, VPN, or provider-level security groups;
- rotate access when operators leave the project.

## Firewall Guidance

The current automation does not force firewall changes. This avoids locking operators out of custom topologies.

Recommended minimum inbound rules for a single-host deployment:

- `22/tcp` from trusted operator IPs only;
- `80/tcp` and `443/tcp` from the internet;
- no public access to `6379`, `9090`, `9091`, `9092`, `3001`, `3002`, `7233`, `8081`, or `6060` unless explicitly protected.

For HA deployments, allow private traffic only between role hosts for Redis, RelayMiner metrics, Provider/Middleman backends, and monitoring scrape targets.

## Grafana Public Access

Grafana is private by default. If public access is enabled:

- set `monitoring_grafana_public_enabled: true`;
- set `reverse_proxy_grafana_enabled: true`;
- configure a dedicated `monitoring_grafana_domain`;
- configure Caddy `basic_auth` using `monitoring_grafana_public_basic_auth_hash`;
- keep Prometheus private.

Validation expects unauthenticated public Grafana requests to return `401`.

## Secrets

Use Ansible Vault or an external secret manager for:

- `igniter_postgres_password`;
- `igniter_provider_app_identity`;
- Provider generated application secrets if not generated on-host;
- Middleman app identity and secrets when enabled;
- `monitoring_grafana_admin_password`;
- Caddy basic auth hashes.

Supplier/operator key custody remains outside Ansible. The inventory records paths or key names only.

## Validation

Run validation after every security-relevant change:

```bash
ansible-playbook -i inventories/generated/<host-name>/hosts.yml playbooks/validate.yml
```

Review the report on each host:

```text
/var/lib/pocket-automations/validation-report.md
```
