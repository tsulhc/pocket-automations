# pocketd

Installs and validates the Pocket Network `pocketd` CLI.

This role supports validation and troubleshooting. Supplier staking remains an Igniter workflow.

Defaults:

- `pocketd_version: latest`
- `pocketd_upgrade: false`
- `pocket_network: beta` maps to `pocket-lego-testnet`
- `pocketd_allow_chain_id_override: false`

The role intentionally does not create wallets, import keys, or submit transactions.
