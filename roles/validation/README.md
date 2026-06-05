# validation

Runs end-to-end checks for Ubuntu hosts, Igniter, Redis, HA RelayMiner, Pocket RPC/gRPC connectivity, backend services, and exposed ports.

The role is executed by `playbooks/validate.yml` and writes a per-host report to:

```text
/var/lib/pocket-automations/validation-report.md
```

Validation distinguishes infrastructure readiness from Igniter application workflows. Supplier staking, supplier updates, unstaking, and reconciliation remain Igniter workflows and are reported as manual/application steps instead of Ansible transactions.

Checks include:

- supported Ubuntu version;
- Docker and Docker Compose availability;
- Pocket RPC and gRPC reachability;
- beta network chain ID mapping;
- Redis connectivity;
- Igniter Provider health and bootstrap report presence;
- Igniter Middleman health when enabled;
- HA RelayMiner relayer health and metrics;
- HA RelayMiner miner metrics;
- configured backend checks from relayer hosts;
- reverse proxy public relay routing;
- Provider API allowlist enforcement;
- Middleman public routing when enabled;
- Provider admin exposure warning when explicitly enabled.

Runtime service checks are collected into PASS/WARN/FAIL lists. The play fails at the end if critical failures were found, after writing the report.
