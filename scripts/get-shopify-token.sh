#!/usr/bin/env bash
# Fetch an Admin API access token (shpat_) for a Shopify custom app
#
# Since 2026, app install no longer always shows "Reveal token once".
# Uses client_credentials flow: Client ID + shpss_ → shpat_ (valid ~24h).
#
# Usage:
#   1. Copy scripts/.env.example → scripts/.env and fill in values
#   2. ./scripts/get-shopify-token.sh
#
# Options:
#   --test       Validate token with a GraphQL shop { name } query
#   --export     Print export commands for the current shell session
#   --json       Raw JSON output from Shopify

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-shopify-auth.sh
source "${SCRIPT_DIR}/lib-shopify-auth.sh"

load_shopify_env

STORE="${SHOPIFY_STORE:-}"
CLIENT_ID="${SHOPIFY_CLIENT_ID:-}"
CLIENT_SECRET="${SHOPIFY_CLIENT_SECRET:-}"
API_VERSION="${SHOPIFY_API_VERSION:-2026-01}"

DO_TEST=false
DO_EXPORT=false
DO_JSON=false

for arg in "$@"; do
  case "$arg" in
    --test) DO_TEST=true ;;
    --export) DO_EXPORT=true ;;
    --json) DO_JSON=true ;;
    -h|--help)
      sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Unknown option: $arg (use --help)" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$STORE" || -z "$CLIENT_ID" || -z "$CLIENT_SECRET" ]]; then
  echo "Missing configuration."
  echo ""
  echo "Create scripts/.env from scripts/.env.example:"
  echo "  cp scripts/.env.example scripts/.env"
  echo ""
  echo "Then set:"
  echo "  SHOPIFY_STORE         → fanshopaperol.myshopify.com"
  echo "  SHOPIFY_CLIENT_ID     → from app (Dev Dashboard or Admin)"
  echo "  SHOPIFY_CLIENT_SECRET → shpss_..."
  exit 1
fi

STORE="$(normalize_shopify_store "$STORE")"

echo "Store: ${STORE}"
echo "Exchanging Client ID + shpss_ for an access token..."
echo ""

TOKEN_RESPONSE=$(fetch_shopify_access_token "$STORE" "$CLIENT_ID" "$CLIENT_SECRET") || exit 1

if $DO_JSON; then
  echo "$TOKEN_RESPONSE" | python3 -m json.tool
  exit 0
fi

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])')
SCOPES=$(echo "$TOKEN_RESPONSE" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("scope",""))')
EXPIRES_IN=$(echo "$TOKEN_RESPONSE" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("expires_in",""))')

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Access token (shpat_) — valid ~24h"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "$ACCESS_TOKEN"
echo ""
echo "Granted scopes : ${SCOPES}"
echo "Expires in     : ${EXPIRES_IN} seconds (~$(( EXPIRES_IN / 3600 ))h)"
echo ""
echo "→ Paste this token into Dynamics / Power Platform connections"
echo "  (API Key or X-Shopify-Access-Token header)"
echo ""

if $DO_EXPORT; then
  echo "# Commands to reuse this token in the current session:"
  echo "export SHOPIFY_STORE=\"${STORE}\""
  echo "export SHOPIFY_ACCESS_TOKEN=\"${ACCESS_TOKEN}\""
  echo ""
fi

if $DO_TEST; then
  echo "GraphQL test (shop { name })..."
  TEST_RESPONSE=$(curl -sS -X POST "https://${STORE}/admin/api/${API_VERSION}/graphql.json" \
    -H "Content-Type: application/json" \
    -H "X-Shopify-Access-Token: ${ACCESS_TOKEN}" \
    -d '{"query":"{ shop { name myshopifyDomain } appInstallation { accessScopes { handle } } }"}')

  echo "$TEST_RESPONSE" | python3 -m json.tool

  if echo "$TEST_RESPONSE" | grep -q '"errors"'; then
    echo ""
    echo "⚠️  Token obtained but the test query failed."
    exit 1
  fi
  echo ""
  echo "✅ Valid token — store accessible."
fi
