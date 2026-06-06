# Setup Wizard

`scripts/generate-inventory.sh` is a local bash wizard that creates a guided `production-single-host` inventory.

The wizard is intended for operators who are new to Ansible but already have access to a VM, domains, backend services, and Pocket supplier key material.

## Why Local First

The wizard runs on the operator workstation or control host, not as a remote bootstrap script. This keeps the first version safer:

- no remote one-liner execution;
- no automatic private key import;
- no staking transactions;
- generated inventory remains visible before deployment;
- Ansible remains the deployment mechanism.

## Run

```bash
scripts/generate-inventory.sh
```

The output is written to:

```text
inventories/generated/<host-name>/hosts.yml
```

## Inputs

The wizard asks for:

- target VM IP or DNS name;
- SSH user;
- SSH private key path;
- Pocket network;
- Pocket RPC and gRPC endpoints;
- Provider domain;
- relay domain;
- TLS contact email;
- Igniter Provider owner identity;
- Igniter Provider owner email;
- Igniter Provider `APP_IDENTITY` value or placeholder;
- PostgreSQL password value or placeholder;
- RelayMiner keys mode;
- backend service ID;
- backend URL;
- optional backend readiness check URL.

## Secret Handling

The wizard can write placeholders such as:

```text
VAULT_OR_SECRET_MANAGER_VALUE
```

Use real secrets only if your generated inventory is protected. For production, prefer Ansible Vault or an external secret manager.

The wizard does not create, copy, import, or validate supplier private keys. It only records where HA RelayMiner should find them on the target host.

## Key Source Modes

Supported modes:

- `keyring`: use a Cosmos keyring directory on the target host.
- `keys_file`: use one supplier keys file on the target host.
- `keys_dir`: use a directory containing supplier key files on the target host.

The operator is responsible for placing the key material at the configured remote path before expecting reward-ready operation.

## Commands After Generation

The wizard prints the next commands:

```bash
ansible-inventory -i inventories/generated/<host-name>/hosts.yml --list
ansible-playbook -i inventories/generated/<host-name>/hosts.yml playbooks/site.yml
ansible-playbook -i inventories/generated/<host-name>/hosts.yml playbooks/validate.yml
```

Run validation after every inventory, DNS, backend, or secret change.
