# Monitoring

The monitoring role deploys Prometheus and Grafana for HA RelayMiner metrics.

It imports the upstream Pocket RelayMiner dashboard from:

```text
https://github.com/pokt-network/pocket-relay-miner/tree/main/tilt/grafana/dashboards
```

The dashboard is versioned in this repository so deployments do not depend on GitHub availability at runtime.

## Components

- Prometheus on `127.0.0.1:9091` by default.
- Grafana on `127.0.0.1:3002` by default.
- Grafana datasource provisioning for Prometheus.
- Grafana dashboard provisioning for the HA RelayMiner unified overview dashboard.

## Default Security Model

Prometheus and Grafana bind to localhost by default.

Use an SSH tunnel for private access:

```bash
ssh -L 3002:127.0.0.1:3002 ubuntu@<vm>
```

Then open:

```text
http://127.0.0.1:3002
```

## Public Grafana

Grafana can be exposed publicly through the reverse proxy role, but only with Caddy basic authentication.

Required inventory values:

```yaml
monitoring_grafana_public_enabled: true
monitoring_grafana_domain: grafana.example.com
monitoring_grafana_public_basic_auth_user: admin
monitoring_grafana_public_basic_auth_hash: CADDY_BCRYPT_HASH_VALUE
reverse_proxy_grafana_enabled: true
```

Generate the Caddy bcrypt hash on a machine with Caddy installed:

```bash
caddy hash-password --plaintext '<password>'
```

Do not expose Grafana without authentication.

## Scrape Targets

Single-host example:

```yaml
monitoring_scrape_jobs:
  - job_name: ha-relayminer-relayer
    targets:
      - 127.0.0.1:9090
  - job_name: ha-relayminer-miner
    targets:
      - 127.0.0.1:9092
```

HA example:

```yaml
monitoring_scrape_jobs:
  - job_name: ha-relayminer-relayers
    targets:
      - 192.0.2.40:9090
      - 192.0.2.41:9090
  - job_name: ha-relayminer-miners
    targets:
      - 192.0.2.50:9092
      - 192.0.2.51:9092
```

Keep raw metrics endpoints private.
