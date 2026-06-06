# Troubleshooting

Start with the validation report:

```bash
ansible-playbook -i <inventory> playbooks/validate.yml
```

Then read:

```text
/var/lib/pocket-automations/validation-report.md
```

## Ansible Warnings

### `INJECT_FACTS_AS_VARS`

This project avoids top-level fact variables such as `ansible_distribution`. If this warning appears again, search for deprecated fact usage in roles and replace it with `ansible_facts[...]`.

### Callback dispatch warnings

Some Ansible versions can print callback warnings unrelated to deployment state. They are not the same as failed tasks. Review the play recap and validation report before treating them as blockers.

## Igniter Dependencies

### Invalid image references such as `postgres:`

Igniter dependency compose requires version variables in `.env`. The role renders explicit PostgreSQL and Temporal versions.

If this appears again, inspect:

```text
/opt/igniter/source/docker-compose/dependencies/.env
```

### Temporal UI port conflict

Temporal UI must not occupy HA RelayMiner relayer port `8080`. The dependency override binds Temporal UI to `127.0.0.1:18080` by default.

## Redis

### Config file permission denied

The Redis container must be able to read `redis.conf`. The role renders it with container-readable permissions.

### `/data` permission denied

Docker Redis needs a writable data directory for the Redis container user. The role owns the data directory with the container Redis UID/GID.

### Protected mode denies HA RelayMiner

Docker Redis binds to localhost on the host and disables Redis protected mode inside the container. Do not expose Redis publicly unless you intentionally configure network controls and authentication.

## Igniter Provider

### Generated secrets do not load

Generated secret files live on the managed host. They must be loaded with remote file handling, not controller-local `include_vars`.

### Provider health fails

Check Provider containers:

```bash
docker ps -a --filter name=provider
docker logs provider-web
docker logs provider-workflows
```

Confirm PostgreSQL and Temporal are running first.

## HA RelayMiner

### Docker build fails with unsupported architecture

The upstream Dockerfile expects `TARGETARCH`. The role maps Ansible architecture facts to Docker build args.

### Relayer health check fails at `/`

The health endpoint is:

```text
http://127.0.0.1:8081/health
```

The root path can return `404` even when the relayer is healthy.

### Relayer starts but no rewards arrive

Relayer-only operation is not reward-ready. Confirm:

- miner is enabled;
- miner metrics endpoint responds;
- supplier keys are present;
- Igniter supplier staking and service configuration are complete;
- backend checks pass.

### Miner exits quickly

Check logs:

```bash
docker logs ha-relayminer-miner
```

Common causes:

- missing supplier keys;
- keyring path not mounted as expected;
- Redis connectivity failure;
- Pocket RPC/gRPC endpoint failure.

## Caddy

### Caddyfile validation fails

Run:

```bash
caddy validate --config /etc/caddy/Caddyfile
```

Check that upstream lists are rendered as space-separated values and that domains are valid.

### TLS does not issue

Confirm:

- DNS points to the VM;
- ports 80 and 443 are reachable from the internet;
- `reverse_proxy_tls_email` is set;
- no other service is bound to public ports 80 or 443.

## Backend Checks

If validation reports no backend checks configured, add `ha_relayminer_backend_checks` to the inventory. Backend checks are important for reward readiness because HA RelayMiner can be healthy while the service backend is not.
