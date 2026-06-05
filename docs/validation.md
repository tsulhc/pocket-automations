# Validation Workflow

Run validation after `playbooks/site.yml` or whenever an operator changes inventory, secrets, DNS, backend services, or reverse proxy settings.

```bash
ansible-playbook -i inventories/production-single-host/hosts.yml playbooks/validate.yml
```

Each host writes a report to:

```text
/var/lib/pocket-automations/validation-report.md
```

The report has four operator-facing sections:

- `PASS`: checks that succeeded.
- `WARN`: non-blocking issues or incomplete optional configuration.
- `FAIL`: problems that should be fixed before considering the deployment ready.
- `Manual Igniter Steps Remaining`: application workflows that must be completed in Igniter, not Ansible.

Important boundaries:

- Ansible validates infrastructure readiness.
- Igniter Provider remains the source of truth for supplier staking, service updates, unstaking, and reconciliation.
- Middleman is delegator-facing and depends on Provider public API being exposed only through the reverse proxy allowlist.
- `COIN_MARKET_CAP_API_KEY` is optional for Middleman and produces at most a warning.

For production testing on a fresh Ubuntu VM, run the flow in this order:

1. Prepare a real inventory with DNS, secrets, backend RPC endpoints, and Pocket RPC/gRPC endpoints.
2. Run `ansible-playbook -i <inventory> playbooks/site.yml`.
3. Run `ansible-playbook -i <inventory> playbooks/validate.yml`.
4. Review the validation report on each host.
5. Complete the remaining Igniter Provider and optional Middleman bootstrap workflows.
6. Re-run validation after bootstrap and any service configuration changes.
