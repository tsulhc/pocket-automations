# redis

Deploys or validates Redis 8.2+ for HA RelayMiner shared state and leader election.

Ubuntu repositories may provide Redis 7.x, so the default mode runs `redis:8.4-alpine` through Docker and binds it to `127.0.0.1:6379`.

Supported modes:

- `redis_deployment_mode: docker`
- `redis_deployment_mode: external`

Redis must never be exposed publicly.
