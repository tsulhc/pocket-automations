# Release Process

Pocket Automations uses small tagged releases once the project reaches a coherent operator-facing state.

## Versioning

Use semantic versioning:

- `v0.x.y` while the project is still stabilizing public operator workflows;
- increment `x` for significant role, inventory, or workflow changes;
- increment `y` for fixes, documentation updates, and compatible improvements.

The first recommended release is `v0.1.0` after CI is green and the HA validation matrix has been reviewed.

## Compatibility Matrix

Current baseline:

- Ubuntu: 22.04 and 24.04 target hosts;
- Ansible: ansible-core 2.21 tested locally and in CI;
- Docker: official Docker Engine packages with Compose plugin;
- Pocket docs source: <https://docs.pocket.network/>;
- RelayMiner: built from `pokt-network/pocket-relay-miner` source;
- Igniter: deployed from the configured upstream Igniter repository ref;
- Caddy: official Caddy apt repository;
- Monitoring: Prometheus and Grafana Docker images pinned through inventory defaults.

Pin production deployments to explicit upstream refs where possible:

```yaml
pocketd_version: vX.Y.Z
igniter_repo_version: <tag-or-commit>
ha_relayminer_repo_version: <tag-or-commit>
monitoring_prometheus_image: prom/prometheus:<tag>
monitoring_grafana_image: grafana/grafana:<tag>
```

## Pre-Release Checklist

Before tagging:

- GitHub Actions are green on `master`;
- `ansible-playbook --syntax-check` passes for `site.yml`, `validate.yml`, and `upgrade.yml`;
- all example inventories parse with `ansible-inventory --list`;
- the setup wizard generates a parseable inventory in interactive and config-file modes;
- documentation does not claim Ansible performs staking, backup, restore, or disaster recovery;
- `CHANGELOG.md` has an entry for the release.

## Tagging

Inspect the final state:

```bash
git status
git log --oneline -10
```

Create and push a tag:

```bash
git tag -a v0.1.0 -m "Release v0.1.0"
git push origin v0.1.0
```

## Release Notes

Release notes should include:

- supported deployment profiles;
- major features;
- known limitations;
- validation status;
- explicit out-of-scope items.

Keep the boundary clear: Ansible provisions and validates infrastructure; Igniter manages supplier lifecycle and staking operations.
