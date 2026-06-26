#!/usr/bin/env bash
# Shopify diagnostic — validates scopes required by the Dynamics / Power Platform connector
#
# Prerequisites: scripts/.env configured (see README.md)
#   ./scripts/get-shopify-token.sh --test
#   ./scripts/test-scopes.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-shopify-auth.sh
source "${SCRIPT_DIR}/lib-shopify-auth.sh"

load_shopify_env

STORE="${SHOPIFY_STORE:-}"
TOKEN="${SHOPIFY_ACCESS_TOKEN:-}"
CLIENT_ID="${SHOPIFY_CLIENT_ID:-}"
CLIENT_SECRET="${SHOPIFY_CLIENT_SECRET:-}"
API_VERSION="${SHOPIFY_API_VERSION:-2026-01}"

if [[ -z "$STORE" ]]; then
  echo "Error: set SHOPIFY_STORE (in scripts/.env or via export)"
  exit 1
fi

STORE="$(normalize_shopify_store "$STORE")"

if [[ -z "$TOKEN" ]]; then
  if [[ -n "$CLIENT_ID" && -n "$CLIENT_SECRET" ]]; then
    echo "No SHOPIFY_ACCESS_TOKEN — fetching via client_credentials..."
    TOKEN_RESPONSE=$(fetch_shopify_access_token "$STORE" "$CLIENT_ID" "$CLIENT_SECRET") || exit 1
    TOKEN=$(echo "$TOKEN_RESPONSE" | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])')
    echo "Token obtained."
    echo ""
  else
    echo "Error: run ./scripts/get-shopify-token.sh first"
    echo "  or set SHOPIFY_ACCESS_TOKEN / SHOPIFY_CLIENT_ID + SHOPIFY_CLIENT_SECRET"
    exit 1
  fi
fi

ENDPOINT="https://${STORE}/admin/api/${API_VERSION}/graphql.json"

run_query() {
  local name="$1"
  local query="$2"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Test: $name"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  response=$(curl -sS -X POST "$ENDPOINT" \
    -H "Content-Type: application/json" \
    -H "X-Shopify-Access-Token: $TOKEN" \
    -d "{\"query\":$(echo "$query" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')}")

  echo "$response" | python3 -m json.tool 2>/dev/null || echo "$response"

  if echo "$response" | grep -q '"ACCESS_DENIED"'; then
    echo "❌ FAILED — missing scope (see errors above)"
    return 1
  elif echo "$response" | grep -q '"errors"'; then
    echo "⚠️  GraphQL error (see above)"
    return 1
  else
    echo "✅ OK"
    return 0
  fi
}

PASS=0
FAIL=0

check() {
  if run_query "$@"; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); fi
}

check "Granted app scopes" \
'query { appInstallation { accessScopes { handle } } }'

check "Orders (read_orders)" \
'query { orders(first: 1) { edges { node { id name } } } }'

check "Products (read_products)" \
'query { products(first: 1) { edges { node { id title } } } }'

check "Locations (read_locations)" \
'query { locations(first: 1) { edges { node { id name } } } }'

check "Customers — connector fields" \
'query { customers(first: 1) { edges { node { id displayName defaultEmailAddress { emailAddress marketingUnsubscribeUrl } lastOrder { id name } } } } }'

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary: $PASS passed, $FAIL failed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
