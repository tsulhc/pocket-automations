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

## Non-Interactive Mode

Use `--config` to generate an inventory from a bash-compatible answers file:

```bash
scripts/generate-inventory.sh --config answers.env --output inventories/generated/provider-01/hosts.yml
```

Use `--dry-run` to print the generated YAML without writing a file:

```bash
scripts/generate-inventory.sh --config answers.env --dry-run
```

Minimal example:

```bash
INVENTORY_NAME=provider-01
ANSIBLE_HOST=203.0.113.10
ANSIBLE_USER=ubuntu
SSH_KEY_PATH=/home/operator/.ssh/id_ed25519

POCKET_NETWORK=main
PROVIDER_DOMAIN=provider.example.com
RELAY_DOMAIN=relay.example.com
TLS_EMAIL=ops@example.com

OWNER_IDENTITY=pokt1replacewithrealowneraddress
OWNER_EMAIL=ops@example.com
APP_IDENTITY=VAULT_OR_SECRET_MANAGER_VALUE
POSTGRES_PASSWORD=VAULT_OR_SECRET_MANAGER_VALUE

KEYS_MODE=keyring
KEYRING_DIR=/etc/pocket-automations/ha-relayminer/keys/keyring
KEY_NAMES=supplier-1

SERVICE_ID=eth
SERVICE_BACKEND_URL=https://eth-backend.example.com
BACKEND_CHECK_ENABLED=true
BACKEND_CHECK_URL=https://eth-backend.example.com

GRAFANA_ADMIN_PASSWORD=VAULT_OR_SECRET_MANAGER_VALUE
GRAFANA_PUBLIC_ENABLED=false
```

Optional public Grafana values:

```bash
GRAFANA_PUBLIC_ENABLED=true
GRAFANA_DOMAIN=grafana.example.com
GRAFANA_BASIC_AUTH_USER=admin
GRAFANA_BASIC_AUTH_HASH='$2a$14$replacewithcaddyhashpasswordoutput'
```

The config file is sourced by bash. Protect it like an inventory file if it contains real secrets.

Supported options:

- `--config <file>`: load answers from a config file.
- `--output <file>`: override the generated inventory path.
- `--dry-run`: print YAML to stdout only.
- `--help`: show command usage.

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
- Grafana admin password or secret placeholder;
- whether Grafana should be exposed publicly;
- Grafana public domain and Caddy basic auth hash when public access is enabled.

The wizard validates common input mistakes before writing YAML:

- hostnames and domains must not include URL schemes or paths;
- RPC/backend URLs must use `http://` or `https://`;
- gRPC endpoints must use `host:port`;
- Provider owner identity must look like a `pokt1...` address;
- Provider, relay, and public Grafana domains must be distinct;
- public Grafana requires a Caddy bcrypt hash.

## Secret Handling

The wizard can write placeholders such as:

```text
VAULT_OR_SECRET_MANAGER_VALUE
```

Use real secrets only if your generated inventory is protected. For production, prefer Ansible Vault or an external secret manager.

The wizard does not create, copy, import, or validate supplier private keys. It only records where HA RelayMiner should find them on the target host.

The wizard can enable public Grafana routing, but it requires a Caddy bcrypt hash. Generate it with:

```bash
caddy hash-password --plaintext '<password>'
```

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
