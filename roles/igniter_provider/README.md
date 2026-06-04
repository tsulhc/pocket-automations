# igniter_provider

Deploys Igniter Provider, which is mandatory for staking operations in this automation.

Provider owns supplier staking workflows, key lifecycle, relay miner records, address groups, services, delegators, and revenue share configuration.

This role deploys the upstream Docker Compose Provider stack:

- `provider-migration`
- `provider-web`
- `provider-workflows`

The role renders `docker-compose/apps/provider/.env`, adds a compose override for image tags and local port binding, starts the compose stack, validates `/api/health`, and writes a bootstrap report for the operator.

Required operator-provided values:

- `igniter_provider_owner_identity`
- `igniter_provider_owner_email`
- `igniter_provider_app_identity`
- `igniter_postgres_password` or `igniter_provider_pgpassword`

The role can generate `ENCRYPTION_IV`, `ENCRYPTION_KEY`, and `AUTH_SECRET` on the managed host. It does not generate `APP_IDENTITY`, create wallets, import keys, or submit staking transactions.
