#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_BASE="${ROOT_DIR}/inventories/generated"
CONFIG_FILE=""
OUTPUT_FILE=""
DRY_RUN="false"

usage() {
  cat <<'USAGE'
Usage: scripts/generate-inventory.sh [options]

Options:
  --config <file>   Load non-interactive answers from a bash-compatible config file.
  --output <file>   Write the generated inventory to this path.
  --dry-run         Print the inventory to stdout instead of writing it.
  -h, --help        Show this help.

Config files use uppercase variable names such as INVENTORY_NAME, ANSIBLE_HOST,
PROVIDER_DOMAIN, RELAY_DOMAIN, and GRAFANA_PUBLIC_ENABLED. See docs/setup-wizard.md.
USAGE
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --config)
        [[ $# -ge 2 ]] || { say "--config requires a file path"; exit 2; }
        CONFIG_FILE="$2"
        shift 2
        ;;
      --output)
        [[ $# -ge 2 ]] || { say "--output requires a file path"; exit 2; }
        OUTPUT_FILE="$2"
        shift 2
        ;;
      --dry-run)
        DRY_RUN="true"
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        say "Unknown option: $1"
        usage
        exit 2
        ;;
    esac
  done
}

load_config() {
  [[ -n "${CONFIG_FILE}" ]] || return 0
  [[ -f "${CONFIG_FILE}" ]] || { say "Config file not found: ${CONFIG_FILE}"; exit 2; }
  # shellcheck source=/dev/null
  source "${CONFIG_FILE}"
}

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

configured_or_prompt() {
  local variable_name="$1"
  local prompt="$2"
  local default_value="${3:-}"
  local prompt_function="$4"
  local value="${!variable_name-}"

  if [[ -n "${value}" ]]; then
    printf '%s' "${value}"
    return 0
  fi

  if [[ -n "${CONFIG_FILE}" ]]; then
    if [[ -n "${default_value}" ]]; then
      printf '%s' "${default_value}"
      return 0
    fi
    say "Missing required config value: ${variable_name}"
    exit 2
  fi

  "${prompt_function}" "${prompt}" "${default_value}"
}

validate_matching_value() {
  local value="$1"
  local pattern="$2"
  local error_message="$3"

  if [[ ! "${value}" =~ ${pattern} ]]; then
    say "${error_message}: ${value}"
    exit 2
  fi
}

validate_choice_value() {
  local value="$1"
  shift
  local allowed=("$@")
  local item

  for item in "${allowed[@]}"; do
    [[ "${value}" == "${item}" ]] && return 0
  done
  say "Invalid value '${value}'. Allowed values: ${allowed[*]}"
  exit 2
}

validate_boolean_value() {
  local value="$1"
  if [[ "${value}" != "true" && "${value}" != "false" ]]; then
    say "Expected true or false, got: ${value}"
    exit 2
  fi
}

validate_distinct_domains() {
  local provider_domain="$1"
  local relay_domain="$2"
  local grafana_public_enabled="$3"
  local grafana_domain="$4"

  if [[ "${provider_domain}" == "${relay_domain}" ]]; then
    say "Provider domain and relay domain must be different."
    exit 2
  fi
  if [[ "${grafana_public_enabled}" == "true" && ( "${grafana_domain}" == "${provider_domain}" || "${grafana_domain}" == "${relay_domain}" ) ]]; then
    say "Grafana public domain must be different from Provider and relay domains."
    exit 2
  fi
}

validate_pokt_address() {
  local value="$1"
  validate_matching_value "${value}" '^pokt1[0-9a-z]+$' "Igniter Provider owner identity must look like a pokt1 address"
}

validate_service_id() {
  local value="$1"
  validate_matching_value "${value}" '^[A-Za-z0-9._-]+$' "Pocket service ID must not contain spaces or URL characters"
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
  # shellcheck disable=SC2016
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

  if [[ "${DRY_RUN}" == "false" ]]; then
    mkdir -p "$(dirname "${output_file}")"
  fi

  local inventory_content
  inventory_content="$(cat <<YAML
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
)"

  if [[ "${DRY_RUN}" == "true" ]]; then
    printf '%s\n' "${inventory_content}"
  else
    printf '%s\n' "${inventory_content}" > "${output_file}"
  fi

  case "${keys_mode}" in
    keys_file)
      cat_or_print "${output_file}" <<YAML
    ha_relayminer_keys_file: "$(yaml_escape "${keys_file}")"
YAML
      ;;
    keys_dir)
      cat_or_print "${output_file}" <<YAML
    ha_relayminer_keys_dir: "$(yaml_escape "${keys_dir}")"
YAML
      ;;
    keyring)
      cat_or_print "${output_file}" <<YAML
    ha_relayminer_keyring_dir: "$(yaml_escape "${keyring_dir}")"
YAML
      if [[ -n "${key_names}" ]]; then
        cat_or_print "${output_file}" <<YAML
    ha_relayminer_key_names:
YAML
        IFS=',' read -r -a names <<< "${key_names}"
        local key_name
        for key_name in "${names[@]}"; do
          key_name="${key_name# }"
          key_name="${key_name% }"
          [[ -z "${key_name}" ]] && continue
          cat_or_print "${output_file}" <<YAML
      - "$(yaml_escape "${key_name}")"
YAML
        done
      fi
      ;;
  esac

  cat_or_print "${output_file}" <<YAML

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
    cat_or_print "${output_file}" <<YAML

    ha_relayminer_validate_backends: true
    ha_relayminer_backend_checks:
      - name: "$(yaml_escape "${service_id}") backend"
        type: http
        url: "$(yaml_escape "${backend_check_url}")"
        method: GET
        status_code: 200
YAML
  else
    cat_or_print "${output_file}" <<YAML

    ha_relayminer_validate_backends: false
YAML
  fi

  cat_or_print "${output_file}" <<YAML

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

cat_or_print() {
  local output_file="$1"

  if [[ "${DRY_RUN}" == "true" ]]; then
    cat
  else
    cat >> "${output_file}"
  fi
}

main() {
  local inventory_name ansible_host ansible_user ssh_key_path network chain_id rpc_url grpc_address
  local provider_domain relay_domain tls_email owner_identity owner_email app_identity postgres_password
  local keys_mode keys_file keys_dir keyring_dir key_names service_id service_backend_url
  local backend_check_enabled backend_check_url output_file
  local grafana_admin_password grafana_public_enabled grafana_domain grafana_basic_auth_user grafana_basic_auth_hash

  if [[ "${DRY_RUN}" == "false" ]]; then
    say "Pocket Automations inventory wizard"
    say "This wizard creates a production-single-host inventory with Provider, Redis, Temporal, HA RelayMiner relayer, and HA RelayMiner miner enabled."
    say "It does not create wallets, import private keys, or submit staking transactions. Igniter remains responsible for supplier lifecycle operations."
    say ""
  fi

  inventory_name="$(configured_or_prompt INVENTORY_NAME "Inventory host name" "pocket-provider-01" ask_required)"
  ansible_host="$(configured_or_prompt ANSIBLE_HOST "Target VM IP or DNS name" "" ask_host)"
  ansible_user="$(configured_or_prompt ANSIBLE_USER "SSH user" "ubuntu" ask_required)"
  ssh_key_path="$(configured_or_prompt SSH_KEY_PATH "SSH private key path" "${HOME}/.ssh/id_ed25519" ask_required)"

  if [[ -n "${POCKET_NETWORK-}" ]]; then
    network="${POCKET_NETWORK}"
  elif [[ -n "${CONFIG_FILE}" ]]; then
    network="main"
  else
    network="$(ask_choice "Pocket network" "main" main beta)"
  fi
  validate_choice_value "${network}" main beta

  if [[ "${network}" == "main" ]]; then
    chain_id="pocket"
    rpc_url="https://sauron-rpc.infra.pocket.network"
    grpc_address="sauron-grpc.infra.pocket.network:443"
  else
    chain_id="pocket-lego-testnet"
    rpc_url="https://sauron-rpc.beta.infra.pocket.network"
    grpc_address="sauron-grpc.beta.infra.pocket.network:443"
  fi

  chain_id="$(configured_or_prompt POCKET_CHAIN_ID "Pocket chain ID" "${chain_id}" ask_required)"
  rpc_url="$(configured_or_prompt POCKET_RPC_URL "Pocket RPC URL" "${rpc_url}" ask_url)"
  grpc_address="$(configured_or_prompt POCKET_GRPC_ADDRESS "Pocket gRPC address" "${grpc_address}" ask_grpc_address)"

  provider_domain="$(configured_or_prompt PROVIDER_DOMAIN "Igniter Provider domain" "" ask_domain)"
  relay_domain="$(configured_or_prompt RELAY_DOMAIN "Public relay domain" "" ask_domain)"
  tls_email="$(configured_or_prompt TLS_EMAIL "TLS/ACME contact email" "" ask_email)"

  owner_identity="$(configured_or_prompt OWNER_IDENTITY "Igniter Provider owner identity" "" ask_required)"
  owner_email="$(configured_or_prompt OWNER_EMAIL "Igniter Provider owner email" "${tls_email}" ask_email)"
  app_identity="$(configured_or_prompt APP_IDENTITY "Igniter Provider APP_IDENTITY secret or Vault placeholder" "VAULT_OR_SECRET_MANAGER_VALUE" ask_required)"
  postgres_password="$(configured_or_prompt POSTGRES_PASSWORD "PostgreSQL password or Vault placeholder" "VAULT_OR_SECRET_MANAGER_VALUE" ask_required)"

  if [[ "${DRY_RUN}" == "false" ]]; then
    say ""
    say "Supplier keys are required for miner reward readiness. The wizard records where keys will be mounted; it does not create or import them."
  fi
  if [[ -n "${KEYS_MODE-}" ]]; then
    keys_mode="${KEYS_MODE}"
  elif [[ -n "${CONFIG_FILE}" ]]; then
    keys_mode="keyring"
  else
    keys_mode="$(ask_choice "RelayMiner keys mode" "keyring" keyring keys_file keys_dir)"
  fi
  validate_choice_value "${keys_mode}" keyring keys_file keys_dir
  keys_file=""
  keys_dir=""
  keyring_dir=""
  key_names="${KEY_NAMES-}"
  case "${keys_mode}" in
    keys_file)
      keys_file="$(configured_or_prompt KEYS_FILE "Remote supplier keys file path" "/etc/pocket-automations/ha-relayminer/keys/supplier-keys.yaml" ask_remote_path)"
      ;;
    keys_dir)
      keys_dir="$(configured_or_prompt KEYS_DIR "Remote supplier keys directory" "/etc/pocket-automations/ha-relayminer/keys/suppliers" ask_remote_path)"
      ;;
    keyring)
      keyring_dir="$(configured_or_prompt KEYRING_DIR "Remote keyring directory" "/etc/pocket-automations/ha-relayminer/keys/keyring" ask_remote_path)"
      if [[ -z "${key_names}" && -z "${CONFIG_FILE}" ]]; then
        key_names="$(ask "Optional comma-separated key names to load" "")"
      fi
      ;;
  esac

  service_id="$(configured_or_prompt SERVICE_ID "Pocket service ID" "eth" ask_required)"
  service_backend_url="$(configured_or_prompt SERVICE_BACKEND_URL "Backend URL for ${service_id}" "" ask_url)"
  if [[ -n "${BACKEND_CHECK_ENABLED-}" ]]; then
    backend_check_enabled="${BACKEND_CHECK_ENABLED}"
  elif [[ -n "${CONFIG_FILE}" ]]; then
    backend_check_enabled="true"
  else
    backend_check_enabled="$(ask_yes_no "Add an HTTP backend readiness check" "yes")"
  fi
  validate_boolean_value "${backend_check_enabled}"
  backend_check_url=""
  if [[ "${backend_check_enabled}" == "true" ]]; then
    backend_check_url="$(configured_or_prompt BACKEND_CHECK_URL "Backend readiness check URL" "${service_backend_url}" ask_url)"
  fi

  if [[ "${DRY_RUN}" == "false" ]]; then
    say ""
    say "Monitoring deploys Prometheus and Grafana. Grafana is private by default and can be accessed with an SSH tunnel."
  fi
  grafana_admin_password="$(configured_or_prompt GRAFANA_ADMIN_PASSWORD "Grafana admin password or Vault placeholder" "VAULT_OR_SECRET_MANAGER_VALUE" ask_required)"
  if [[ -n "${GRAFANA_PUBLIC_ENABLED-}" ]]; then
    grafana_public_enabled="${GRAFANA_PUBLIC_ENABLED}"
  elif [[ -n "${CONFIG_FILE}" ]]; then
    grafana_public_enabled="false"
  else
    grafana_public_enabled="$(ask_yes_no "Expose Grafana publicly through Caddy basic auth" "no")"
  fi
  validate_boolean_value "${grafana_public_enabled}"
  grafana_domain=""
  grafana_basic_auth_user=""
  grafana_basic_auth_hash=""
  if [[ "${grafana_public_enabled}" == "true" ]]; then
    grafana_domain="$(configured_or_prompt GRAFANA_DOMAIN "Grafana public domain" "" ask_domain)"
    grafana_basic_auth_user="$(configured_or_prompt GRAFANA_BASIC_AUTH_USER "Grafana public basic auth user" "admin" ask_required)"
    [[ "${DRY_RUN}" == "false" ]] && say "Generate the bcrypt hash with: caddy hash-password --plaintext '<password>'"
    grafana_basic_auth_hash="$(configured_or_prompt GRAFANA_BASIC_AUTH_HASH "Grafana public basic auth bcrypt hash" "" ask_caddy_bcrypt_hash)"
  fi

  validate_matching_value "${inventory_name}" '^[A-Za-z0-9._-]+$' "Inventory host name must be a safe inventory key"
  validate_matching_value "${ansible_host}" '^[A-Za-z0-9._:-]+$' "Use a hostname, IP address, or host:port value without spaces"
  validate_matching_value "${rpc_url}" '^https?://[^[:space:]]+$' "Use an http:// or https:// Pocket RPC URL without spaces"
  validate_matching_value "${grpc_address}" '^[A-Za-z0-9._-]+:[0-9]+$' "Use a Pocket gRPC host:port without scheme or spaces"
  validate_matching_value "${provider_domain}" '^[A-Za-z0-9][A-Za-z0-9.-]*[A-Za-z0-9]$' "Use a Provider DNS name without scheme, path, or spaces"
  validate_matching_value "${relay_domain}" '^[A-Za-z0-9][A-Za-z0-9.-]*[A-Za-z0-9]$' "Use a relay DNS name without scheme, path, or spaces"
  validate_matching_value "${tls_email}" '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' "Use a valid TLS email address"
  validate_matching_value "${owner_email}" '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' "Use a valid Provider owner email address"
  validate_pokt_address "${owner_identity}"
  validate_service_id "${service_id}"
  validate_matching_value "${service_backend_url}" '^https?://[^[:space:]]+$' "Use an http:// or https:// backend URL without spaces"
  [[ "${backend_check_enabled}" == "true" ]] && validate_matching_value "${backend_check_url}" '^https?://[^[:space:]]+$' "Use an http:// or https:// backend check URL without spaces"
  [[ -n "${keys_file}" ]] && validate_matching_value "${keys_file}" '^/[^[:space:]]+$' "Use an absolute remote supplier keys file path without spaces"
  [[ -n "${keys_dir}" ]] && validate_matching_value "${keys_dir}" '^/[^[:space:]]+$' "Use an absolute remote supplier keys directory without spaces"
  [[ -n "${keyring_dir}" ]] && validate_matching_value "${keyring_dir}" '^/[^[:space:]]+$' "Use an absolute remote keyring directory without spaces"
  if [[ "${grafana_public_enabled}" == "true" ]]; then
    validate_matching_value "${grafana_domain}" '^[A-Za-z0-9][A-Za-z0-9.-]*[A-Za-z0-9]$' "Use a Grafana DNS name without scheme, path, or spaces"
    # shellcheck disable=SC2016
    validate_matching_value "${grafana_basic_auth_hash}" '^\$2[abxy]?\$[0-9]{2}\$.{53}$' "Use a Caddy bcrypt hash generated with caddy hash-password"
  fi
  validate_distinct_domains "${provider_domain}" "${relay_domain}" "${grafana_public_enabled}" "${grafana_domain}"

  output_file="${OUTPUT_FILE:-${OUTPUT_BASE}/${inventory_name}/hosts.yml}"
  write_inventory "${output_file}" "${inventory_name}" "${ansible_host}" "${ansible_user}" "${ssh_key_path}" \
    "${network}" "${chain_id}" "${rpc_url}" "${grpc_address}" "${provider_domain}" "${relay_domain}" \
    "${tls_email}" "${owner_identity}" "${owner_email}" "${app_identity}" "${postgres_password}" \
    "${keys_mode}" "${keys_file}" "${keys_dir}" "${keyring_dir}" "${key_names}" "${service_id}" \
    "${service_backend_url}" "${backend_check_enabled}" "${backend_check_url}" "${grafana_admin_password}" \
    "${grafana_public_enabled}" "${grafana_domain}" "${grafana_basic_auth_user}" "${grafana_basic_auth_hash}"

  if [[ "${DRY_RUN}" == "false" ]]; then
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
  fi
}

parse_args "$@"
load_config
main
