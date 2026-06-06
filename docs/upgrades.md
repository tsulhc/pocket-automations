# Upgrades

Use `playbooks/upgrade.yml` for day-2 component updates after the initial deployment.

The upgrade playbook is intentionally scoped to deployed software and configuration. It does not perform backup, restore, disaster recovery, staking, unstaking, or supplier lifecycle operations.

## Full Upgrade

```bash
ansible-playbook -i inventories/generated/<host-name>/hosts.yml playbooks/upgrade.yml
```

The full run updates components in this order:

1. common host prerequisites and Docker runtime checks;
2. `pocketd` CLI;
3. Igniter Provider;
4. optional Igniter Middleman;
5. HA RelayMiner relayers and miners;
6. Prometheus/Grafana monitoring;
7. Caddy reverse proxy;
8. validation report.

## Component Upgrades

Run a single component with tags:

```bash
ansible-playbook -i inventories/generated/<host-name>/hosts.yml playbooks/upgrade.yml --tags pocketd
ansible-playbook -i inventories/generated/<host-name>/hosts.yml playbooks/upgrade.yml --tags igniter
ansible-playbook -i inventories/generated/<host-name>/hosts.yml playbooks/upgrade.yml --tags relayminer
ansible-playbook -i inventories/generated/<host-name>/hosts.yml playbooks/upgrade.yml --tags monitoring
ansible-playbook -i inventories/generated/<host-name>/hosts.yml playbooks/upgrade.yml --tags reverse_proxy
```

Validation can be run separately:

```bash
ansible-playbook -i inventories/generated/<host-name>/hosts.yml playbooks/validate.yml
```

## Version Pins

Prefer explicit version pins for production changes:

```yaml
pocketd_version: vX.Y.Z
igniter_repo_version: <tag-or-commit>
ha_relayminer_repo_version: <tag-or-commit>
monitoring_prometheus_image: prom/prometheus:<tag>
monitoring_grafana_image: grafana/grafana:<tag>
```

Using `main` or `latest` is convenient for labs but should be treated as an intentional production decision.

## HA RelayMiner Rolling Strategy

`playbooks/upgrade.yml` uses serial execution for HA RelayMiner by default:

```yaml
upgrade_relayminer_serial: 1
```

This updates one relayer/miner host at a time. Increase only if the topology can tolerate simultaneous component restarts.

## Post-Upgrade Checks

After upgrades, confirm:

- `playbooks/validate.yml` reports no `FAIL` items;
- relayer health responds at `/health`;
- relayer and miner metrics respond;
- Prometheus and Grafana are healthy;
- public relay TLS still works;
- Grafana public endpoint, if enabled, still requires authentication;
- Igniter Provider UI/workflows are healthy before running any lifecycle operation.
