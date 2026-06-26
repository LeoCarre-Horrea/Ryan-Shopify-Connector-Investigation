# Token renewal — Shopify custom app & Dynamics connector

Store: `fanshopaperol.myshopify.com`

The Dynamics connector authenticates to Shopify with an **Admin API access token** (`shpat_...`). With the current Shopify custom app model, that token is obtained via **Client ID + Client secret** (`shpss_...`) and **expires after approximately 24 hours**.

| Side                          | Responsibility                                                          |
| ----------------------------- | ----------------------------------------------------------------------- |
| **Shopify**                   | Custom app scopes, credentials, token generation, API validation        |
| **Dynamics / Power Platform** | Storing and updating the token in connections, retesting virtual tables |

> The `shpss_` secret is **not** the API token. Only `shpat_` belongs in Dynamics connections.

---

## Part 1 — Shopify (custom app & scripts) (Already done)

### Required Admin API scopes

These scopes must be enabled on the custom app under **Admin API integration** (not Customer Account API):

```
read_customers
write_customers
read_orders
read_products
read_locations
read_inventory
```

After any scope change: **reinstall the app**, then generate a new token.

### Credentials

From **Shopify Admin → Settings → Apps and sales channels → Develop apps → [Dynamics app] → Credentials**:

| Variable                | Source                        |
| ----------------------- | ----------------------------- |
| `SHOPIFY_STORE`         | `fanshopaperol.myshopify.com` |
| `SHOPIFY_CLIENT_ID`     | Client ID                     |
| `SHOPIFY_CLIENT_SECRET` | Client secret (`shpss_...`)   |

### One-time script setup

```bash
cp scripts/.env.example scripts/.env
chmod +x scripts/*.sh
# Edit scripts/.env with the values above
```

Security: never commit `scripts/.env` or share secrets/tokens in email or chat.

### Generate and validate a token

```bash
./scripts/renew-token.sh
```

This script:

1. Exchanges Client ID + `shpss_` for a new `shpat_`
2. Tests shop access
3. Runs 5 GraphQL checks (orders, products, locations, customers)

**Expected result:** `5 réussis, 0 échoués` / all scope checks passed.

Other commands:

```bash
./scripts/get-shopify-token.sh --test   # token + shop test only
./scripts/test-scopes.sh              # scope checks only
```

### Shopify-side troubleshooting

| Symptom                                                | Likely cause                        | Action                                                    |
| ------------------------------------------------------ | ----------------------------------- | --------------------------------------------------------- |
| HTTP error when running scripts                        | Wrong Client ID or `shpss_`         | Re-copy from Shopify Credentials                          |
| Scope checks fail (not 5/5)                            | Missing or changed Admin API scopes | Review scopes in Shopify Admin, reinstall app             |
| `read_marketplace_orders` in API errors                | Misleading GraphQL message          | Ignore — `read_orders` is sufficient                      |
| Worked yesterday, scripts still OK but connector fails | Token expired in Dynamics           | Generate a new `shpat_` and hand off to Dynamics (Part 2) |

When Part 1 passes (5/5), the Shopify side is ready. Share the new `shpat_` securely with the team responsible for Dynamics connections.

---

## Part 2 — Dynamics / Power Platform

> **Unverified instructions.**  
> The steps below are **recommended procedures** suggested by AI based on public Microsoft / Power Platform documentation and common integration patterns. They have **not been validated** against your specific tenant, environment, connection names, or virtual table setup. Menus and labels may differ. Treat this as a checklist to adapt locally — not as ground truth.

### What to update

After receiving a valid `shpat_` from Part 1, update the **API Key** (or equivalent) everywhere the Shopify token is stored.

**Typical connection fields:**

| Field     | Value                               |
| --------- | ----------------------------------- |
| Store URL | `fanshopaperol.myshopify.com`       |
| API Key   | `shpat_...` (new token from Part 1) |

### Suggested locations (adapt to your environment)

#### Power Apps

1. Open [make.powerapps.com](https://make.powerapps.com)
2. Select the target **environment**
3. Open **Connections**
4. Locate the **Shopify** connection used by apps or virtual tables
5. **Edit** → replace API Key with the new `shpat_` → **Save**

#### Power Automate

1. Open [make.powerautomate.com](https://make.powerautomate.com)
2. Same **environment**
3. **Connections** → Shopify connection → **Edit** → new `shpat_`

#### Dataverse virtual tables

If Shopify data is exposed as virtual tables:

- Update the **underlying connection** used by the virtual connector provider
- If solutions use a **connection reference**, confirm it still points to the updated connection
- Paths such as **Settings → Advanced settings** may apply depending on how the integration was built

#### Environment variables / Key Vault

If the token is stored in an environment variable or Azure Key Vault, update it there and ensure dependent connections pick up the new value (may require re-saving or refreshing connections).

### Suggested retest

After updating connections, retry reads on:

- customers
- orders
- products
- locations

Confirm there are no `ACCESS_DENIED` errors.

### Dynamics-side troubleshooting (AI suggestions)

| Symptom                                      | Likely cause                | Suggested action                                                  |
| -------------------------------------------- | --------------------------- | ----------------------------------------------------------------- |
| `ACCESS_DENIED` on orders/products/customers | Stale token in Dynamics     | Confirm Part 1 is 5/5, then update all Shopify connections        |
| Errors persist after token update            | Not all connections updated | Audit Power Apps, Power Automate, connection references, env vars |
| Intermittent failures ~24h apart             | Token expiry                | Repeat Part 1 + Part 2 on a schedule                              |

### Optional automation (AI suggestion)

A scheduled **Power Automate** flow could:

1. `POST` to `https://fanshopaperol.myshopify.com/admin/oauth/access_token` with `grant_type=client_credentials`
2. Parse `access_token` from the response
3. Update a connection, environment variable, or Key Vault — **if** your tenant supports updating those programmatically

Feasibility depends on your security model and connector capabilities; validate before relying on this in production.

---

## End-to-end workflow

```
Shopify (Part 1)                    Dynamics (Part 2)
─────────────────                   ───────────────────
./scripts/renew-token.sh     →    Update shpat_ in connections
5/5 scope checks OK          →    Retest virtual tables
(shpat_ valid ~24h)          →    Repeat when token expires or errors return
```

---

## Quick reference

```bash
./scripts/renew-token.sh              # recommended — Part 1 full run
./scripts/get-shopify-token.sh --test
./scripts/test-scopes.sh
```

Configuration file: `scripts/.env` (from `scripts/.env.example`).
