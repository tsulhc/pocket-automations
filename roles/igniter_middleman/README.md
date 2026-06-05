# igniter_middleman

Deploys optional Igniter Middleman for delegator-facing staking workflows.

Middleman is disabled by default and is enabled with `igniter_middleman_enabled: true`.

This role:

- clones the upstream Igniter repository;
- renders the Middleman `.env` file;
- deploys `middleman-migration`, `middleman-web`, and `middleman-workflows` with Docker Compose;
- generates `AUTH_SECRET` on the managed host when it is not supplied;
- validates Middleman health;
- optionally validates Provider public API connectivity through the reverse proxy allowlist;
- writes a bootstrap report for the operator.

This role does not generate or import `APP_IDENTITY`. Provide it through Ansible Vault or an external secret manager.

`COIN_MARKET_CAP_API_KEY` is optional. If it is omitted, coin value display may be degraded, but the deployment is allowed.

Required inputs when enabled:

- `middleman_domain`
- `igniter_middleman_owner_identity`
- `igniter_middleman_owner_email`
- `igniter_middleman_app_identity`
- `igniter_postgres_password` or `igniter_middleman_pgpassword`
- `pocket_rpc_url`
- `pocket_chain_id`

Provider integration requires:

- `provider_public_api_domain`
- `reverse_proxy_provider_public_api_enabled: true`

Provider remains the staking lifecycle source of truth. Middleman is public and delegator-facing.
