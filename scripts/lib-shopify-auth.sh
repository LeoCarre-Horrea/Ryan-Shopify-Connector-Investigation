#!/usr/bin/env bash
# Fonctions partagées — authentification Shopify custom app (client credentials)

normalize_shopify_store() {
  local store="$1"
  store="${store#https://}"
  store="${store#http://}"
  store="${store%%/*}"
  if [[ "$store" != *.* ]]; then
    store="${store}.myshopify.com"
  fi
  echo "$store"
}

load_shopify_env() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  if [[ -f "${script_dir}/.env" ]]; then
    # shellcheck disable=SC1091
    set -a
    source "${script_dir}/.env"
    set +a
  fi
}

fetch_shopify_access_token() {
  local store="$1"
  local client_id="$2"
  local client_secret="$3"

  if [[ -z "$store" || -z "$client_id" || -z "$client_secret" ]]; then
    echo "Erreur: SHOPIFY_STORE, SHOPIFY_CLIENT_ID et SHOPIFY_CLIENT_SECRET sont requis." >&2
    return 1
  fi

  store="$(normalize_shopify_store "$store")"

  local response http_code body
  response=$(curl -sS -w "\n%{http_code}" -X POST "https://${store}/admin/oauth/access_token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=client_credentials&client_id=${client_id}&client_secret=${client_secret}")

  http_code="${response##*$'\n'}"
  body="${response%$'\n'*}"

  if [[ "$http_code" != "200" ]]; then
    echo "Erreur HTTP ${http_code} lors de l'obtention du token:" >&2
    echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body" >&2
    return 1
  fi

  echo "$body"
}
