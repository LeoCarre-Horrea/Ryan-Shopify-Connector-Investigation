# Shopify / Dynamics 365 connector

Investigation and resolution of `ACCESS_DENIED` errors on Dataverse tables **customers**, **orders**, **products**, and **locations**.

## Structure

```
├── README.md
├── docs/
│   ├── STATUS.md                 ← summary and remaining actions
│   ├── DYNAMICS-GUIDE.md         ← Power Platform connections / retest
│   └── TOKEN-RENEWAL-GUIDE.md    ← token renewal (Shopify + Dynamics)
├── errors/                       ← initial connector error logs
│   ├── customers.txt
│   ├── orders.txt
│   └── products.txt
└── scripts/                      ← Shopify token generation and validation
    ├── README.md
    ├── renew-token.sh
    ├── get-shopify-token.sh
    ├── test-scopes.sh
    └── .env.example
```

## Documentation

| Document | Contents |
|----------|----------|
| [docs/STATUS.md](docs/STATUS.md) | Investigation summary, status, remaining actions |
| [docs/DYNAMICS-GUIDE.md](docs/DYNAMICS-GUIDE.md) | Updating Dynamics connections + retest |
| [docs/TOKEN-RENEWAL-GUIDE.md](docs/TOKEN-RENEWAL-GUIDE.md) | Token renewal — Part 1 Shopify / Part 2 Dynamics |
| [scripts/README.md](scripts/README.md) | Shopify scripts (Part 1) |

## Responsibilities

| Area | Responsibility |
|------|----------------|
| **Shopify** | Custom app scopes, `shpat_` generation, API validation (`scripts/`) |
| **Dynamics** | Power Platform connection updates, virtual table retest |

## Current status

Admin API scopes fixed, local tests **5/5 OK**. See [docs/STATUS.md](docs/STATUS.md).
