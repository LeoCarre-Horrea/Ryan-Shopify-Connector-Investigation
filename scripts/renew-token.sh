#!/usr/bin/env bash
# Shopify token renewal — Part 1 (generate shpat_ + validate scopes)
#
#   cp scripts/.env.example scripts/.env
#   ./scripts/renew-token.sh
#
# Dynamics connection updates: docs/TOKEN-RENEWAL-GUIDE.md → Part 2

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -f "${SCRIPT_DIR}/.env" ]]; then
  echo "Missing scripts/.env"
  echo ""
  echo "  cp scripts/.env.example scripts/.env"
  echo "  # Edit with Shopify Admin → Develop apps → Credentials"
  echo ""
  echo "See docs/TOKEN-RENEWAL-GUIDE.md → Part 1"
  exit 1
fi

echo "══════════════════════════════════════════════════════════════"
echo "  Shopify token renewal (Part 1)"
echo "══════════════════════════════════════════════════════════════"
echo ""

"${SCRIPT_DIR}/get-shopify-token.sh" --test
echo ""

echo "Running scope checks..."
if "${SCRIPT_DIR}/test-scopes.sh"; then
  SCOPE_OK=true
else
  SCOPE_OK=false
fi

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  Handoff — Dynamics / Power Platform (Part 2)"
echo "══════════════════════════════════════════════════════════════"
echo ""
echo "Copy the shpat_ token printed above."
echo "Update Dynamics connections — see docs/DYNAMICS-GUIDE.md"
echo "(AI-suggested steps; adapt to your tenant.)"
echo ""
echo "Do NOT paste shpss_ into Dynamics — only shpat_."
echo "Token expires in ~24h."
echo ""

if $SCOPE_OK; then
  echo "✅ Part 1 complete (5/5) — safe to update Dynamics with this token."
else
  echo "❌ Scope checks failed — fix Shopify app/scopes before updating Dynamics."
  echo "   See docs/TOKEN-RENEWAL-GUIDE.md → Part 1 → Troubleshooting"
  exit 1
fi
