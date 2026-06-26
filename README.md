# Connecteur Shopify / Dynamics 365

Investigation et résolution des erreurs `ACCESS_DENIED` sur les tables Dataverse **customers**, **orders**, **products** et **locations**.

## Structure

```
├── README.md
├── docs/
│   ├── STATUS.md                 ← bilan et suite à faire
│   ├── DYNAMICS-GUIDE.md         ← connexions Power Platform / retest
│   └── TOKEN-RENEWAL-GUIDE.md    ← renouvellement token (Shopify + Dynamics)
├── errors/                       ← logs d'erreur initiaux du connecteur
│   ├── customers.txt
│   ├── orders.txt
│   └── products.txt
└── scripts/                      ← génération et validation token Shopify
    ├── README.md
    ├── renew-token.sh
    ├── get-shopify-token.sh
    ├── test-scopes.sh
    └── .env.example
```

## Documentation

| Document | Contenu |
|----------|---------|
| [docs/STATUS.md](docs/STATUS.md) | Bilan investigation, statut, actions restantes |
| [docs/DYNAMICS-GUIDE.md](docs/DYNAMICS-GUIDE.md) | Mise à jour des connexions Dynamics + retest |
| [docs/TOKEN-RENEWAL-GUIDE.md](docs/TOKEN-RENEWAL-GUIDE.md) | Renouvellement token — Part 1 Shopify / Part 2 Dynamics |
| [scripts/README.md](scripts/README.md) | Scripts côté Shopify (Part 1) |

## Répartition

| Périmètre | Responsabilité |
|-----------|----------------|
| **Shopify** | Scopes custom app, génération `shpat_`, validation API (`scripts/`) |
| **Dynamics** | Mise à jour connexions Power Platform, retest tables virtuelles |

## État actuel

Scopes Admin API corrigés, tests locaux **5/5 OK**. Voir [docs/STATUS.md](docs/STATUS.md).
