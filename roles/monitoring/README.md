# Monitoring Role

Deploys Prometheus and Grafana for HA RelayMiner metrics.

The role imports the upstream Pocket RelayMiner Grafana dashboard from `tilt/grafana/dashboards/unified-overview.json` as a versioned project asset. Prometheus scrape targets are inventory-driven so single-host and HA topologies can keep metrics private.

Grafana binds to `127.0.0.1:3002` by default. Public Grafana routing is handled by the `reverse_proxy` role and must use Caddy basic authentication.
