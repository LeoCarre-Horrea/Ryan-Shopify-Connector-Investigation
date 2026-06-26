# Statut — Connecteur Shopify / Dynamics

*Dernière mise à jour : juin 2026 — boutique `fanshopaperol.myshopify.com` (Aperol Official Online Shop)*

---

## Le token 24h règle-t-il le problème ?

**Non — ce sont deux sujets distincts.**

| Sujet | Nature | Statut |
|-------|--------|--------|
| **Scopes Admin API manquants** | Cause des erreurs `ACCESS_DENIED` | ✅ **Résolu** |
| **Expiration du token (~24h)** | Contrainte du flux `client_credentials` | ⚠️ **À gérer en exploitation** |

### Ce qui a corrigé les erreurs

1. Ajout des scopes **Admin API** (pas Customer Account API) :
   - `read_orders`, `read_products`, `read_customers`, `write_customers`, `read_locations`, `read_inventory`
2. Réinstallation de l'app + nouveau token avec ces permissions
3. Tests locaux validés (**5/5**)

Une fois le token propagé dans Dynamics, les erreurs de scopes ne devraient plus apparaître — tant que le token en cours est valide.

### Le sujet des 24h

Le `shpat_` obtenu via `client_credentials` **expire après ~24h**. Ce n'est pas la cause initiale des `ACCESS_DENIED`, mais peut provoquer de nouvelles pannes si Dynamics utilise un token expiré.

**Options :**

1. **Court terme** — Régénérer le token (`scripts/renew-token.sh`) et mettre à jour les connexions Dynamics
2. **Moyen terme** — Flow Power Automate planifié (si faisable dans le tenant)
3. **Long terme** — Évaluer OAuth complet côté connecteur

---

## Ce qui a été fait

- [x] Analyse des logs d'erreur initiaux (`errors/`)
- [x] Cause racine : scopes **Admin API** absents (confusion avec `customer_read_*`)
- [x] Documentation `read_marketplace_orders` (ignorable — `read_orders` suffit)
- [x] Scripts token + validation scopes (`scripts/`)
- [x] Configuration scopes sur la custom app Shopify
- [x] Validation API : orders, products, locations, customers

### Résultat des tests

| Test | Résultat |
|------|----------|
| Scopes accordés | ✅ |
| `orders` | ✅ |
| `products` | ✅ |
| `locations` | ✅ |
| `customers` (champs connecteur) | ✅ |

---

## Ce qu'il reste à faire

### Côté Dynamics / Power Platform

- [ ] Configurer `scripts/.env` avec les credentials fournis et valider via `renew-token.sh`
- [ ] Mettre à jour le `shpat_` dans toutes les connexions concernées
  - Power Apps → Connections
  - Power Automate → Connections
  - Dataverse → connection references (tables virtuelles)
  - Variables d'environnement / Key Vault si utilisées
- [ ] Retester les tables `customers`, `orders`, `products`, `locations`
- [ ] Confirmer que l'intégration fonctionne de bout en bout

→ Procédure : [docs/DYNAMICS-GUIDE.md](DYNAMICS-GUIDE.md)

### Exploitation

- [x] Guides documentés (`TOKEN-RENEWAL-GUIDE.md`, `DYNAMICS-GUIDE.md`)
- [ ] Transmettre credentials + scripts (pas le token par email) ; cadence de renouvellement ~24h

### Optionnel

- [ ] Distinguer cette custom app de l'app **Business Central** officielle (OAuth séparé)
- [ ] Centraliser le token dans **Azure Key Vault**

---

## Scopes Admin API (référence)

**Shopify Admin → Développer des apps → [App Dynamics] → Admin API integration** :

```
read_customers
write_customers
read_orders
read_products
read_locations
read_inventory
```

> Ne pas confondre avec les scopes **Customer Account API** (`customer_read_*`).

---

## Scripts

```bash
./scripts/renew-token.sh              # token + validation (Part 1)
./scripts/get-shopify-token.sh --test
./scripts/test-scopes.sh
```

Configuration : `scripts/.env` (ne pas committer).
