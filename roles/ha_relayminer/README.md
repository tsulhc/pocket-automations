# ha_relayminer

Deploys HA RelayMiner relayer and miner components.

The relayer handles relay ingress and backend proxying. The miner consumes Redis streams and submits claims and proofs.

Default deployment mode is Docker build from the upstream `pokt-network/pocket-relay-miner` repository because no GitHub release artifacts are currently published.

The role determines which components to run from inventory groups:

- hosts in `relay_relayers` run `pocket-relay-miner relayer`.
- hosts in `relay_miners` run `pocket-relay-miner miner`.
- hosts in both groups run both components.

Default Docker networking is `network_mode: host` for predictable Ubuntu deployments and local Redis compatibility. Use firewall and reverse proxy roles to control public exposure.

Required inputs:

- `ha_relayminer_redis_url`
- `pocket_rpc_url`
- `pocket_grpc_address`
- `pocket_chain_id`
- `relay_services` on relayer hosts
- supplier/operator keys at the configured key source

Supported key source modes:

- `keyring`
- `keys_file`
- `keys_dir`

The role does not generate, import, or custody supplier keys. Igniter Provider remains responsible for supplier staking and lifecycle workflows; HA RelayMiner only performs relay serving plus operational claim/proof submission for configured suppliers.

Optional backend checks can be configured with `ha_relayminer_backend_checks`:

```yaml
ha_relayminer_backend_checks:
  - name: eth-jsonrpc
    type: http
    url: https://eth-backend.example.internal/health
    status_code: 200
  - name: eth-grpc
    type: tcp
    host: eth-backend.example.internal
    port: 50051
```
