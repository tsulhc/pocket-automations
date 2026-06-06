# Beginner Deployment Guide

This guide walks a new operator through a production-oriented single-host deployment. It includes Igniter Provider, PostgreSQL, Temporal, Redis, HA RelayMiner relayer, HA RelayMiner miner, and Caddy reverse proxy.

Ansible prepares and validates infrastructure. Igniter remains responsible for supplier staking, supplier updates, unstaking, delegator workflows, and staking lifecycle operations.

## What This Guide Deploys

- Pocket CLI tooling through `pocketd`.
- Igniter Provider for supplier lifecycle operations.
- PostgreSQL and Temporal for Igniter.
- Redis for HA RelayMiner coordination.
- HA RelayMiner relayer for relay traffic.
- HA RelayMiner miner for supplier/session coordination and reward-relevant operation.
- Caddy for public TLS relay ingress.
- Prometheus and Grafana for HA RelayMiner monitoring.

## What This Guide Does Not Do

- It does not create wallets.
- It does not import private keys.
- It does not stake a supplier.
- It does not update supplier services on-chain.
- It does not guarantee rewards until Igniter bootstrap and supplier lifecycle workflows are complete.

## Prerequisites

You need:

- One Ubuntu 24.04 or 22.04 VM.
- SSH access to the VM.
- A domain for public relay traffic, for example `relayer.example.com`.
- A domain for Igniter Provider, for example `provider.example.com`.
- DNS records pointing those domains to the VM.
- A Pocket network choice: `main` or `beta`.
- A backend service URL for each service you want to relay, for example an Ethereum JSON-RPC endpoint.
- Supplier/operator key material already prepared outside this automation.
- An Igniter Provider `APP_IDENTITY` supplied through Vault or another secret source.

## Step 1: Generate An Inventory

Run the local inventory wizard from the repository root:

```bash
scripts/generate-inventory.sh
```

The wizard creates an inventory under:

```text
inventories/generated/<host-name>/hosts.yml
```

The wizard asks for:

- SSH target and user.
- Pocket network and endpoints.
- Provider and relay domains.
- Igniter Provider owner identity and email.
- Provider `APP_IDENTITY` placeholder or secret value.
- PostgreSQL password placeholder or secret value.
- HA RelayMiner key source mode.
- Backend service ID and backend URL.

Keep generated inventories private if they contain real secrets. Prefer Ansible Vault or an external secret manager for production values.

## Step 2: Inspect The Inventory

Run:

```bash
ansible-inventory -i inventories/generated/<host-name>/hosts.yml --list
```

Fix inventory errors before deploying.

## Step 3: Deploy Infrastructure

Run:

```bash
ansible-playbook -i inventories/generated/<host-name>/hosts.yml playbooks/site.yml
```

This installs and configures the stack. The first run can take time because Docker images are pulled and HA RelayMiner is built from upstream source.

## Step 4: Run Validation

Run:

```bash
ansible-playbook -i inventories/generated/<host-name>/hosts.yml playbooks/validate.yml
```

Then read the report on the target host:

```text
/var/lib/pocket-automations/validation-report.md
```

Treat `FAIL` items as blockers. Treat `WARN` items as decisions to review before production use.

## Step 5: Complete Igniter Provider Bootstrap

After the infrastructure is up, complete the Igniter Provider bootstrap workflow in the Provider UI.

Use Igniter to configure:

- supplier identity and ownership;
- services;
- relay miner URLs;
- address groups;
- delegator policy, if applicable;
- supplier staking and lifecycle operations.

Ansible does not perform these actions.

## Step 6: Confirm Reward Readiness

A deployment is not reward-ready just because containers are running.

Before expecting rewards, confirm:

- `playbooks/validate.yml` has no `FAIL` items.
- HA RelayMiner relayer health responds at `/health`.
- HA RelayMiner miner metrics responds when miner is enabled.
- Supplier/operator keys are present at the configured key source.
- Igniter Provider bootstrap is complete.
- Supplier staking and service configuration are complete in Igniter.
- Backend service checks pass from the relayer host.
- Public relay DNS and TLS work.

## Step 7: Open Grafana

Grafana is private by default. Use an SSH tunnel:

```bash
ssh -L 3002:127.0.0.1:3002 ubuntu@<vm>
```

Then open:

```text
http://127.0.0.1:3002
```

If the setup wizard enabled public Grafana, open the configured Grafana domain and authenticate with the Caddy basic auth credentials.

Use `docs/post-deploy-checklist.md` for the full checklist.
