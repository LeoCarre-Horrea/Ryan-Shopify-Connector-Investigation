# Shopify token scripts

Scripts to generate and validate the **Shopify Admin API token** (`shpat_`) used by the Dynamics connector.

Covers **Part 1 (Shopify)** of [TOKEN-RENEWAL-GUIDE.md](../docs/TOKEN-RENEWAL-GUIDE.md). See [DYNAMICS-GUIDE.md](../docs/DYNAMICS-GUIDE.md) for connection updates.

## Prerequisites

- macOS, Linux, or WSL
- `curl` and `python3`
- Shopify Admin access → Develop apps → Dynamics custom app → Credentials

## Setup

```bash
cp scripts/.env.example scripts/.env
chmod +x scripts/*.sh
```

Edit `scripts/.env`:

```env
SHOPIFY_STORE=fanshopaperol.myshopify.com
SHOPIFY_CLIENT_ID=
SHOPIFY_CLIENT_SECRET=shpss_
```

Never commit `scripts/.env`.

## Renewal

```bash
./scripts/renew-token.sh
```

Expect **5/5** scope checks. Share the `shpat_` securely — see [DYNAMICS-GUIDE.md](../docs/DYNAMICS-GUIDE.md) for connection updates.

## Scripts

| Script | Purpose |
|--------|---------|
| `renew-token.sh` | Token + scope checks + handoff reminder |
| `get-shopify-token.sh --test` | Token + shop test |
| `test-scopes.sh` | Scope validation only |
