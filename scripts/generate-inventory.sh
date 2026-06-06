#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_BASE="${ROOT_DIR}/inventories/generated"

say() {
  printf '%s\n' "$*"
}

ask() {
  local prompt="$1"
  local default_value="${2:-}"
  local value

  if [[ -n "${default_value}" ]]; then
    read -r -p "${prompt} [${default_value}]: " value
    printf '%s' "${value:-${default_value}}"
  else
    read -r -p "${prompt}: " value
    printf '%s' "${value}"
  fi
}

ask_required() {
  local prompt="$1"
  local default_value="${2:-}"
  local value

  while true; do
    value="$(ask "${prompt}" "${default_value}")"
    if [[ -n "${value}" ]]; then
      printf '%s' "${value}"
      return 0
    fi
    say "This value is required."
  done
}

ask_choice() {
  local prompt="$1"
  local default_value="$2"
  shift 2
  local allowed=("$@")
  local value
  local item

  while true; do
    value="$(ask "${prompt}" "${default_value}")"
    for item in "${allowed[@]}"; do
      if [[ "${value}" == "${item}" ]]; then
        printf '%s' "${value}"
        return 0
      fi
    done
    say "Allowed values: ${allowed[*]}"
  done
}

ask_yes_no() {
  local prompt="$1"
  local default_value="$2"
  local value

  while true; do
    value="$(ask "${prompt} (yes/no)" "${default_value}")"
    case "${value}" in
      yes|y) printf 'true'; return 0 ;;
      no|n) printf 'false'; return 0 ;;
      *) say "Enter yes or no." ;;
    esac
  done
}

yaml_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '%s' "${value}"
}

ask_matching() {
  local prompt="$1"
  local default_value="$2"
  local pattern="$3"
  local error_message="$4"
  local value

  while true; do
    value="$(ask_required "${prompt}" "${default_value}")"
    if [[ "${value}" =~ ${pattern} ]]; then
      printf '%s' "${value}"
      return 0
    fi
    say "${error_message}"
  done
}

ask_host() {
  ask_matching "$1" "${2:-}" '^[A-Za-z0-9._:-]+$' "Use a hostname, IP address, or host:port value without spaces."
}

ask_domain() {
  ask_matching "$1" "${2:-}" '^[A-Za-z0-9][A-Za-z0-9.-]*[A-Za-z0-9]$' "Use a DNS name without scheme, path, or spaces."
}

ask_email() {
  ask_matching "$1" "${2:-}" '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' "Use a valid email address."
}

ask_url() {
  ask_matching "$1" "${2:-}" '^https?://[^[:space:]]+$' "Use an http:// or https:// URL without spaces."
}

ask_grpc_address() {
  ask_matching "$1" "${2:-}" '^[A-Za-z0-9._-]+:[0-9]+$' "Use host:port without scheme, path, or spaces."
}

ask_remote_path() {
  ask_matching "$1" "${2:-}" '^/[^[:space:]]+$' "Use an absolute remote path without spaces."
}

ask_caddy_bcrypt_hash() {
  ask_matching "$1" "${2:-}" '^\$2[abxy]?\$[0-9]{2}\$.{53}$' "Use a Caddy bcrypt hash generated with caddy hash-password."
}

write_inventory() {
  local output_file="$1"
  local inventory_name="$2"
  local ansible_host="$3"
  local ansible_user="$4"
  local ssh_key_path="$5"
  local network="$6"
  local chain_id="$7"
  local rpc_url="$8"
  local grpc_address="$9"
  local provider_domain="${10}"
  local relay_domain="${11}"
  local tls_email="${12}"
  local owner_identity="${13}"
  local owner_email="${14}"
  local app_identity="${15}"
  local postgres_password="${16}"
  local keys_mode="${17}"
  local keys_file="${18}"
  local keys_dir="${19}"
  local keyring_dir="${20}"
  local key_names="${21}"
  local service_id="${22}"
  local service_backend_url="${23}"
  local backend_check_enabled="${24}"
  local backend_check_url="${25}"
  local grafana_admin_password="${26}"
  local grafana_public_enabled="${27}"
  local grafana_domain="${28}"
  local grafana_basic_auth_user="${29}"
  local grafana_basic_auth_hash="${30}"

  mkdir -p "$(dirname "${output_file}")"
  cat > "${output_file}" <<YAML
---
all:
  vars:
    ansible_user: "$(yaml_escape "${ansible_user}")"
    ansible_ssh_private_key_file: "$(yaml_escape "${ssh_key_path}")"

    pocket_network: "$(yaml_escape "${network}")"
    pocket_chain_id: "$(yaml_escape "${chain_id}")"
    pocket_rpc_url: "$(yaml_escape "${rpc_url}")"
    pocket_grpc_address: "$(yaml_escape "${grpc_address}")"

    igniter_provider_enabled: true
    igniter_middleman_enabled: false
    ha_relayminer_enabled: true

    provider_domain: "$(yaml_escape "${provider_domain}")"
    provider_public_api_domain: "provider-api.$(yaml_escape "${provider_domain}")"
    relay_public_domain: "$(yaml_escape "${relay_domain}")"

    reverse_proxy_engine: caddy
    reverse_proxy_tls_email: "$(yaml_escape "${tls_email}")"
    reverse_proxy_relay_enabled: true
    reverse_proxy_relay_backends:
      - http://127.0.0.1:8080
    reverse_proxy_provider_admin_enabled: false
    reverse_proxy_provider_public_api_enabled: false
    reverse_proxy_middleman_enabled: false
    reverse_proxy_grafana_enabled: ${grafana_public_enabled}

    monitoring_enabled: true
    monitoring_grafana_admin_password: "$(yaml_escape "${grafana_admin_password}")"
    monitoring_grafana_public_enabled: ${grafana_public_enabled}
    monitoring_grafana_domain: "$(yaml_escape "${grafana_domain}")"
    monitoring_grafana_public_basic_auth_user: "$(yaml_escape "${grafana_basic_auth_user}")"
    monitoring_grafana_public_basic_auth_hash: "$(yaml_escape "${grafana_basic_auth_hash}")"
    monitoring_scrape_jobs:
      - job_name: ha-relayminer-relayer
        targets:
          - 127.0.0.1:9090
      - job_name: ha-relayminer-miner
        targets:
          - 127.0.0.1:9092

    postgres_deployment_mode: docker
    temporal_deployment_mode: docker
    redis_deployment_mode: docker
    redis_bind_address: 127.0.0.1
    redis_port: 6379

    ha_relayminer_install_mode: docker_build
    ha_relayminer_network_mode: host
    ha_relayminer_redis_url: redis://127.0.0.1:6379
    ha_relayminer_keys_mode: "$(yaml_escape "${keys_mode}")"
YAML

  case "${keys_mode}" in
    keys_file)
      cat >> "${output_file}" <<YAML
    ha_relayminer_keys_file: "$(yaml_escape "${keys_file}")"
YAML
      ;;
    keys_dir)
      cat >> "${output_file}" <<YAML
    ha_relayminer_keys_dir: "$(yaml_escape "${keys_dir}")"
YAML
      ;;
    keyring)
      cat >> "${output_file}" <<YAML
    ha_relayminer_keyring_dir: "$(yaml_escape "${keyring_dir}")"
YAML
      if [[ -n "${key_names}" ]]; then
        cat >> "${output_file}" <<YAML
    ha_relayminer_key_names:
YAML
        IFS=',' read -r -a names <<< "${key_names}"
        local key_name
        for key_name in "${names[@]}"; do
          key_name="${key_name# }"
          key_name="${key_name% }"
          [[ -z "${key_name}" ]] && continue
          cat >> "${output_file}" <<YAML
      - "$(yaml_escape "${key_name}")"
YAML
        done
      fi
      ;;
  esac

  cat >> "${output_file}" <<YAML

    relay_services:
      - service_id: "$(yaml_escape "${service_id}")"
        validation_mode: optimistic
        timeout_profile: fast
        public_url: "https://$(yaml_escape "${relay_domain}")"
        default_backend: jsonrpc
        backends:
          jsonrpc:
            load_balancing: round_robin
            urls:
              - "$(yaml_escape "${service_backend_url}")"
YAML

  if [[ "${backend_check_enabled}" == "true" ]]; then
    cat >> "${output_file}" <<YAML

    ha_relayminer_validate_backends: true
    ha_relayminer_backend_checks:
      - name: "$(yaml_escape "${service_id}") backend"
        type: http
        url: "$(yaml_escape "${backend_check_url}")"
        method: GET
        status_code: 200
YAML
  else
    cat >> "${output_file}" <<YAML

    ha_relayminer_validate_backends: false
YAML
  fi

  cat >> "${output_file}" <<YAML

    igniter_postgres_password: "$(yaml_escape "${postgres_password}")"
    igniter_provider_owner_identity: "$(yaml_escape "${owner_identity}")"
    igniter_provider_owner_email: "$(yaml_escape "${owner_email}")"
    igniter_provider_app_identity: "$(yaml_escape "${app_identity}")"

  children:
    provider_hosts:
      hosts:
        ${inventory_name}:
          ansible_host: "$(yaml_escape "${ansible_host}")"
    middleman_hosts:
      hosts: {}
    postgres_hosts:
      hosts:
        ${inventory_name}:
    temporal_hosts:
      hosts:
        ${inventory_name}:
    redis_hosts:
      hosts:
        ${inventory_name}:
    relay_relayers:
      hosts:
        ${inventory_name}:
    relay_miners:
      hosts:
        ${inventory_name}:
    reverse_proxy_hosts:
      hosts:
        ${inventory_name}:
    monitoring_hosts:
      hosts:
        ${inventory_name}:
    pocket_cli_hosts:
      hosts:
        ${inventory_name}:
YAML
}

main() {
  local inventory_name ansible_host ansible_user ssh_key_path network chain_id rpc_url grpc_address
  local provider_domain relay_domain tls_email owner_identity owner_email app_identity postgres_password
  local keys_mode keys_file keys_dir keyring_dir key_names service_id service_backend_url
  local backend_check_enabled backend_check_url output_file
  local grafana_admin_password grafana_public_enabled grafana_domain grafana_basic_auth_user grafana_basic_auth_hash

  say "Pocket Automations inventory wizard"
  say "This wizard creates a production-single-host inventory with Provider, Redis, Temporal, HA RelayMiner relayer, and HA RelayMiner miner enabled."
  say "It does not create wallets, import private keys, or submit staking transactions. Igniter remains responsible for supplier lifecycle operations."
  say ""

  inventory_name="$(ask_required "Inventory host name" "pocket-provider-01")"
  ansible_host="$(ask_host "Target VM IP or DNS name")"
  ansible_user="$(ask_required "SSH user" "ubuntu")"
  ssh_key_path="$(ask_required "SSH private key path" "~/.ssh/id_ed25519")"

  network="$(ask_choice "Pocket network" "main" main beta)"
  if [[ "${network}" == "main" ]]; then
    chain_id="pocket"
    rpc_url="https://sauron-rpc.infra.pocket.network"
    grpc_address="sauron-grpc.infra.pocket.network:443"
  else
    chain_id="pocket-lego-testnet"
    rpc_url="https://sauron-rpc.beta.infra.pocket.network"
    grpc_address="sauron-grpc.beta.infra.pocket.network:443"
  fi

  chain_id="$(ask_required "Pocket chain ID" "${chain_id}")"
  rpc_url="$(ask_url "Pocket RPC URL" "${rpc_url}")"
  grpc_address="$(ask_grpc_address "Pocket gRPC address" "${grpc_address}")"

  provider_domain="$(ask_domain "Igniter Provider domain")"
  relay_domain="$(ask_domain "Public relay domain")"
  tls_email="$(ask_email "TLS/ACME contact email")"

  owner_identity="$(ask_required "Igniter Provider owner identity")"
  owner_email="$(ask_email "Igniter Provider owner email" "${tls_email}")"
  app_identity="$(ask_required "Igniter Provider APP_IDENTITY secret or Vault placeholder" "VAULT_OR_SECRET_MANAGER_VALUE")"
  postgres_password="$(ask_required "PostgreSQL password or Vault placeholder" "VAULT_OR_SECRET_MANAGER_VALUE")"

  say ""
  say "Supplier keys are required for miner reward readiness. The wizard records where keys will be mounted; it does not create or import them."
  keys_mode="$(ask_choice "RelayMiner keys mode" "keyring" keyring keys_file keys_dir)"
  keys_file=""
  keys_dir=""
  keyring_dir=""
  key_names=""
  case "${keys_mode}" in
    keys_file)
      keys_file="$(ask_remote_path "Remote supplier keys file path" "/etc/pocket-automations/ha-relayminer/keys/supplier-keys.yaml")"
      ;;
    keys_dir)
      keys_dir="$(ask_remote_path "Remote supplier keys directory" "/etc/pocket-automations/ha-relayminer/keys/suppliers")"
      ;;
    keyring)
      keyring_dir="$(ask_remote_path "Remote keyring directory" "/etc/pocket-automations/ha-relayminer/keys/keyring")"
      key_names="$(ask "Optional comma-separated key names to load" "")"
      ;;
  esac

  service_id="$(ask_required "Pocket service ID" "eth")"
  service_backend_url="$(ask_url "Backend URL for ${service_id}")"
  backend_check_enabled="$(ask_yes_no "Add an HTTP backend readiness check" "yes")"
  backend_check_url=""
  if [[ "${backend_check_enabled}" == "true" ]]; then
    backend_check_url="$(ask_url "Backend readiness check URL" "${service_backend_url}")"
  fi

  say ""
  say "Monitoring deploys Prometheus and Grafana. Grafana is private by default and can be accessed with an SSH tunnel."
  grafana_admin_password="$(ask_required "Grafana admin password or Vault placeholder" "VAULT_OR_SECRET_MANAGER_VALUE")"
  grafana_public_enabled="$(ask_yes_no "Expose Grafana publicly through Caddy basic auth" "no")"
  grafana_domain=""
  grafana_basic_auth_user=""
  grafana_basic_auth_hash=""
  if [[ "${grafana_public_enabled}" == "true" ]]; then
    grafana_domain="$(ask_domain "Grafana public domain")"
    grafana_basic_auth_user="$(ask_required "Grafana public basic auth user" "admin")"
    say "Generate the bcrypt hash with: caddy hash-password --plaintext '<password>'"
    grafana_basic_auth_hash="$(ask_caddy_bcrypt_hash "Grafana public basic auth bcrypt hash")"
  fi

  output_file="${OUTPUT_BASE}/${inventory_name}/hosts.yml"
  write_inventory "${output_file}" "${inventory_name}" "${ansible_host}" "${ansible_user}" "${ssh_key_path}" \
    "${network}" "${chain_id}" "${rpc_url}" "${grpc_address}" "${provider_domain}" "${relay_domain}" \
    "${tls_email}" "${owner_identity}" "${owner_email}" "${app_identity}" "${postgres_password}" \
    "${keys_mode}" "${keys_file}" "${keys_dir}" "${keyring_dir}" "${key_names}" "${service_id}" \
    "${service_backend_url}" "${backend_check_enabled}" "${backend_check_url}" "${grafana_admin_password}" \
    "${grafana_public_enabled}" "${grafana_domain}" "${grafana_basic_auth_user}" "${grafana_basic_auth_hash}"

  say ""
  say "Inventory written to: ${output_file}"
  say ""
  say "Next commands:"
  say "  ansible-inventory -i ${output_file} --list"
  say "  ansible-playbook -i ${output_file} playbooks/site.yml"
  say "  ansible-playbook -i ${output_file} playbooks/validate.yml"
  say ""
  if [[ "${grafana_public_enabled}" == "true" ]]; then
    say "Grafana will be available at: https://${grafana_domain}"
  else
    say "Grafana is private. After deploy, use: ssh -L 3002:127.0.0.1:3002 ${ansible_user}@${ansible_host}"
  fi
  say "Reward readiness still requires successful Igniter Provider bootstrap and supplier lifecycle configuration in Igniter."
}

main "$@"
