#!/usr/bin/env bash
# Récupère un Admin API access token (shpat_) pour une custom app Shopify
#
# Depuis 2026, l'installation de l'app ne montre plus toujours "Reveal token once".
# On utilise le flux client_credentials : Client ID + shpss_ → shpat_ (valide 24h).
#
# Usage :
#   1. Copier scripts/.env.example → scripts/.env et remplir les valeurs
#   2. ./scripts/get-shopify-token.sh
#
# Options :
#   --test       Valide le token avec une requête GraphQL shop { name }
#   --export     Affiche les commandes export pour la session courante
#   --json       Sortie JSON brute de Shopify

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
      echo "Option inconnue: $arg (utilisez --help)" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$STORE" || -z "$CLIENT_ID" || -z "$CLIENT_SECRET" ]]; then
  echo "Configuration manquante."
  echo ""
  echo "Créez scripts/.env à partir de scripts/.env.example :"
  echo "  cp scripts/.env.example scripts/.env"
  echo ""
  echo "Puis renseignez :"
  echo "  SHOPIFY_STORE         → fanshopaperol.myshopify.com"
  echo "  SHOPIFY_CLIENT_ID     → depuis l'app (Dev Dashboard ou Admin)"
  echo "  SHOPIFY_CLIENT_SECRET → shpss_..."
  exit 1
fi

STORE="$(normalize_shopify_store "$STORE")"

echo "Boutique : ${STORE}"
echo "Échange Client ID + shpss_ contre un access token..."
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
echo "Access token (shpat_) — valide ~24h"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "$ACCESS_TOKEN"
echo ""
echo "Scopes accordés : ${SCOPES}"
echo "Expire dans     : ${EXPIRES_IN} secondes (~$(( EXPIRES_IN / 3600 ))h)"
echo ""
echo "→ Collez ce token dans les connexions Dynamics / Power Platform"
echo "  (API Key ou header X-Shopify-Access-Token)"
echo ""

if $DO_EXPORT; then
  echo "# Commandes pour réutiliser ce token dans la session :"
  echo "export SHOPIFY_STORE=\"${STORE}\""
  echo "export SHOPIFY_ACCESS_TOKEN=\"${ACCESS_TOKEN}\""
  echo ""
fi

if $DO_TEST; then
  echo "Test GraphQL (shop { name })..."
  TEST_RESPONSE=$(curl -sS -X POST "https://${STORE}/admin/api/${API_VERSION}/graphql.json" \
    -H "Content-Type: application/json" \
    -H "X-Shopify-Access-Token: ${ACCESS_TOKEN}" \
    -d '{"query":"{ shop { name myshopifyDomain } appInstallation { accessScopes { handle } } }"}')

  echo "$TEST_RESPONSE" | python3 -m json.tool

  if echo "$TEST_RESPONSE" | grep -q '"errors"'; then
    echo ""
    echo "⚠️  Le token a été obtenu mais la requête de test a échoué."
    exit 1
  fi
  echo ""
  echo "✅ Token valide — boutique accessible."
fi
