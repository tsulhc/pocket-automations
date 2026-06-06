# Secret Rotation

This guide documents rotation boundaries for secrets managed or referenced by Pocket Automations.

Supplier/operator private key lifecycle is not managed by Ansible. Use Igniter and the operator's key custody process for supplier lifecycle operations.

## Grafana Admin Password

Update inventory or Vault value:

```yaml
monitoring_grafana_admin_password: <new-secret>
```

Apply monitoring:

```bash
ansible-playbook -i inventories/generated/<host-name>/hosts.yml playbooks/upgrade.yml --tags monitoring
```

Then log in with the new password and run validation.

## Public Grafana Basic Auth

Generate a new Caddy bcrypt hash:

```bash
caddy hash-password --plaintext '<new-password>'
```

Update:

```yaml
monitoring_grafana_public_basic_auth_hash: <new-caddy-bcrypt-hash>
```

Apply the reverse proxy:

```bash
ansible-playbook -i inventories/generated/<host-name>/hosts.yml playbooks/upgrade.yml --tags reverse_proxy
```

Validation should confirm that unauthenticated public Grafana returns `401`.

## PostgreSQL Password

`igniter_postgres_password` is consumed by Igniter Provider/Middleman and the local PostgreSQL deployment when self-hosted.

Password rotation is not fully automatic yet because it requires coordinated database credential changes and application restarts. Treat this as a controlled maintenance operation:

- change the database user password using the database administration path;
- update the inventory or Vault value;
- rerun Igniter Provider and Middleman roles;
- validate Provider and Middleman health.

Do not rotate this value during active staking lifecycle operations.

## Igniter Provider Generated Secrets

Provider generated secrets include encryption and auth material. Rotating them may invalidate existing sessions or encrypted application data depending on upstream Igniter behavior.

Current recommendation:

- generate them once on the managed host or provide them through Vault;
- do not rotate casually;
- consult upstream Igniter guidance before rotating encryption keys;
- after any rotation, rerun Provider and validate health before using staking workflows.

## Igniter Middleman Secrets

Middleman `APP_IDENTITY` and app secrets must come from the operator's secret source.

If Middleman is enabled, rotate during a maintenance window:

```bash
ansible-playbook -i inventories/generated/<host-name>/hosts.yml playbooks/upgrade.yml --tags igniter_middleman
```

Then validate Middleman health and public routing.

## What Ansible Does Not Rotate

Ansible does not rotate:

- supplier/operator private keys;
- owner identity keys;
- on-chain staking state;
- Igniter lifecycle decisions.

Those remain under Igniter and the operator's custody model.
