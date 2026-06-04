# igniter_dependencies

Deploys or validates PostgreSQL and Temporal for Igniter Provider and optional Middleman.

Initial support covers two modes:

- `postgres_deployment_mode: docker` and `temporal_deployment_mode: docker`: clone Igniter and start the upstream dependencies compose stack.
- `postgres_deployment_mode: external` and `temporal_deployment_mode: external`: validate TCP connectivity to externally managed dependencies.

Mixed local/external dependency modes are intentionally deferred until Provider and Middleman environment rendering is implemented.
