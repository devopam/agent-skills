# Research: domain-fintech

**Snapshot:** 2026-09-15

## Role

**Overlay** on regional privacy packs — does not replace them. Triggers when the product handles payments, accounts, lending, wallets, or similar.

## Primary / standard sources (v0 orientation)

| Topic | Source | Notes |
|-------|--------|--------|
| Cardholder data security | **PCI DSS** — [PCI SSC standards](https://www.pcisecuritystandards.org/standards/) | Industry standard mandated by payment brands; not a government statute. Still “primary” for card-data security themes |
| Regional privacy | privacy-* packs | Always pair |
| US consumer finance privacy | e.g. GLBA (when researched) | **Not covered** until registry + cards exist |
| EU payments / PSD2-style | **Not covered** until researched |
| India RBI / payment data | **Not covered** until researched |

## Obligation themes (v0)

1. Is payment account data stored/processed/transmitted? → PCI scope discussion + SAQ/ROC awareness (orientation only)
2. Subprocessors (payment gateways, KYC vendors) inventory + contracts
3. Minimization of PAN/SAD in logs and analytics
4. Cross-border settlement vs privacy transfer themes

## Repo signals

Stripe/Adyen/Braintree, card forms, “PCI”, wallet, lending, KYC/AML vendors, open banking.

## Explicit limits

No claim of PCI certification. No invention of RBI/PSD2 obligations until packs exist.
