# Status — Shopify / Dynamics connector

*Last updated: June 2026 — store `fanshopaperol.myshopify.com` (Aperol Official Online Shop)*

---

## Does the 24h token fix the problem?

**No — these are two separate issues.**

| Topic | Nature | Status |
|-------|--------|--------|
| **Missing Admin API scopes** | Cause of `ACCESS_DENIED` errors | ✅ **Resolved** |
| **Token expiry (~24h)** | `client_credentials` flow constraint | ⚠️ **Ongoing operations** |

### What actually fixed the errors

1. Added **Admin API** scopes (not Customer Account API):
   - `read_orders`, `read_products`, `read_customers`, `write_customers`, `read_locations`, `read_inventory`
2. Reinstalled the app + new token with those permissions
3. Local tests validated (**5/5**)

Once the token is propagated in Dynamics, scope errors should no longer appear — as long as the active token is valid.

### The 24h topic

The `shpat_` obtained via `client_credentials` **expires after ~24h**. This was not the initial cause of `ACCESS_DENIED`, but can cause new failures if Dynamics uses an expired token.

**Options:**

1. **Short term** — Regenerate the token (`scripts/renew-token.sh`) and update Dynamics connections
2. **Medium term** — Scheduled Power Automate flow (if feasible in the tenant)
3. **Long term** — Evaluate full OAuth on the connector side

---

## Completed

- [x] Analysis of initial error logs (`errors/`)
- [x] Root cause: missing **Admin API** scopes (confusion with `customer_read_*`)
- [x] Documented `read_marketplace_orders` (ignorable — `read_orders` is enough)
- [x] Token + scope validation scripts (`scripts/`)
- [x] Scope configuration on the Shopify custom app
- [x] API validation: orders, products, locations, customers

### Test results

| Test | Result |
|------|--------|
| Granted scopes | ✅ |
| `orders` | ✅ |
| `products` | ✅ |
| `locations` | ✅ |
| `customers` (connector fields) | ✅ |

---

## Remaining actions

### Dynamics / Power Platform side

- [ ] Configure `scripts/.env` with provided credentials and validate via `renew-token.sh`
- [ ] Update `shpat_` in all relevant connections
  - Power Apps → Connections
  - Power Automate → Connections
  - Dataverse → connection references (virtual tables)
  - Environment variables / Key Vault if used
- [ ] Retest tables `customers`, `orders`, `products`, `locations`
- [ ] Confirm end-to-end integration works

→ Procedure: [docs/DYNAMICS-GUIDE.md](DYNAMICS-GUIDE.md)

### Operations

- [x] Guides documented (`TOKEN-RENEWAL-GUIDE.md`, `DYNAMICS-GUIDE.md`)
- [ ] Share credentials + scripts (not the token by email); ~24h renewal cadence

### Optional

- [ ] Keep this custom app separate from the official **Business Central** app (separate OAuth)
- [ ] Centralize the token in **Azure Key Vault**

---

## Admin API scopes (reference)

**Shopify Admin → Develop apps → [Dynamics app] → Admin API integration**:

```
read_customers
write_customers
read_orders
read_products
read_locations
read_inventory
```

> Do not confuse with **Customer Account API** scopes (`customer_read_*`).

---

## Scripts

```bash
./scripts/renew-token.sh              # token + validation (Part 1)
./scripts/get-shopify-token.sh --test
./scripts/test-scopes.sh
```

Configuration: `scripts/.env` (do not commit).
