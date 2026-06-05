# reverse_proxy

Configures TLS and routing for Provider, Middleman, and relay endpoints.

Provider admin UI must remain private by default. Public Provider API exposure must use the Middleman allowlist.

The default implementation uses Caddy for automatic TLS and simple inventory-driven routing.

Default security posture:

- Relay ingress can be public.
- Provider admin UI is not exposed unless `reverse_proxy_provider_admin_enabled: true`.
- Provider public API is exposed only when enabled and only through `reverse_proxy_provider_api_allowed_paths`.
- Middleman is exposed only when enabled.
- Redis, PostgreSQL, Temporal, pprof, and metrics ports are never proxied by this role.

Required inputs for public TLS endpoints:

- `reverse_proxy_tls_email`
- `relay_public_domain` or `reverse_proxy_relay_domain`
- `provider_public_api_domain` when Provider public API is enabled
- `middleman_domain` when Middleman is enabled

Example:

```yaml
reverse_proxy_engine: caddy
reverse_proxy_tls_email: ops@example.com

reverse_proxy_relay_enabled: true
reverse_proxy_relay_domain: relayer.example.com
reverse_proxy_relay_backends:
  - http://127.0.0.1:8080

reverse_proxy_provider_admin_enabled: false
reverse_proxy_provider_public_api_enabled: true
reverse_proxy_provider_public_api_domain: provider-api.example.com
reverse_proxy_provider_public_api_backend: http://127.0.0.1:3001

reverse_proxy_middleman_enabled: true
reverse_proxy_middleman_domain: staking.example.com
reverse_proxy_middleman_backend: http://127.0.0.1:3000
```
