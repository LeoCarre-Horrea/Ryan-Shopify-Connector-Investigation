# Dynamics / Power Platform — Shopify connector

Store: `fanshopaperol.myshopify.com`

---

## Context

The `ACCESS_DENIED` errors on the **customers**, **orders**, **products**, and **locations** tables were caused by missing **Shopify Admin API** scopes on the custom app. The Shopify side has been fixed and validated (all connector GraphQL queries pass locally).

**Dynamics side:** update the Shopify **access token** in Power Platform / Dataverse connections and retest the virtual tables.

| Credential | Where it goes |
|------------|---------------|
| `shpat_...` (Admin API access token) | Dynamics connections — field usually named **API Key** |
| `shpss_...` (client secret) | **Never** paste into Dynamics — Shopify only |

---

## Token generation

Access tokens are **not** sent by email. Credentials and scripts are provided to generate a fresh `shpat_` locally.

**Setup (one-time):**

```bash
cp scripts/.env.example scripts/.env
# Fill in SHOPIFY_STORE, SHOPIFY_CLIENT_ID, SHOPIFY_CLIENT_SECRET (provided separately)
chmod +x scripts/*.sh
```

**Each renewal:**

```bash
./scripts/renew-token.sh
```

Expect **5/5** scope checks before updating Dynamics. See [TOKEN-RENEWAL-GUIDE.md](TOKEN-RENEWAL-GUIDE.md) Part 1 for details.

**Typical connection fields:**

| Field | Value |
|-------|--------|
| Store URL | `fanshopaperol.myshopify.com` |
| API Key | `shpat_...` (from `./scripts/renew-token.sh`) |

> **Heads-up — token expiry:** with Shopify’s current custom app model, each `shpat_` expires after approximately **24 hours**. This is separate from the scope fix. Plan to run `renew-token.sh` and update Dynamics connections on that cadence (daily, or whenever queries start failing).

---

## Update connections

> **Unverified instructions.**  
> The steps below are **recommended procedures** suggested by AI based on public Microsoft / Power Platform documentation. They have **not been validated** against your specific tenant, environment, connection names, or virtual table setup. Adapt menus and labels to match what you see locally.

### Power Apps

1. Open [make.powerapps.com](https://make.powerapps.com)
2. Select the correct **environment**
3. Open **Connections**
4. Find the **Shopify** connection used by apps or virtual tables
5. **Edit** → replace **API Key** with the new `shpat_` → **Save**

### Power Automate

1. Open [make.powerautomate.com](https://make.powerautomate.com)
2. Same **environment**
3. **Connections** → Shopify connection → **Edit** → new `shpat_`

### Dataverse virtual tables

If Shopify data is exposed as virtual tables:

- Update the **underlying connection** used by the virtual connector provider
- If solutions use a **connection reference**, confirm it points to the updated connection
- Check **Settings → Advanced settings** if that matches how the integration was built

### Environment variables / Key Vault

If the token is stored in an environment variable or Azure Key Vault, update it there and refresh dependent connections.

---

## Retest

After updating all relevant connections, retry reads on:

- [ ] customers  
- [ ] orders  
- [ ] products  
- [ ] locations  

Confirm there are no `ACCESS_DENIED` errors.

---

## Troubleshooting

| Symptom | Suggested action |
|---------|------------------|
| `ACCESS_DENIED` persists | Confirm every Shopify connection was updated (Power Apps, Power Automate, connection references, env vars) |
| Worked yesterday, fails today | Token expired (~24h) — run `./scripts/renew-token.sh`, update all connections |
| `read_marketplace_orders` in error text | Ignore — not required; `read_orders` covers this use case |
| Errors on Shopify fields after token update | Escalate to Shopify app owner — may be a scope issue |

---

## Reference — scopes configured (Shopify side)

For context only — no action needed on the Dynamics side:

```
read_orders, read_products, read_customers, write_customers, read_locations, read_inventory
```

These are **Admin API** scopes. They differ from Customer Account API scopes (`customer_read_*`), which do not satisfy the connector.

---

## Optional — automation (AI suggestion)

A scheduled Power Automate flow could refresh the token automatically. Feasibility depends on the tenant and security model.
