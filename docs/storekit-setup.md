# StoreKit setup

The app ships with a local `Stepper/Stepper.storekit` configuration so the
paywall, restore flow, and entitlement checks all work in Xcode previews
and Simulator without an Apple Developer account. This document covers:

1. How to wire the local config into your scheme (one-time, ~30 s).
2. What you need to create in App Store Connect before submission.
3. How to verify entitlements are flowing end-to-end.

> Reminder: the prices below are **placeholders**. Final prices/tiers will
> be locked in App Store Connect during submission. The product
> identifiers, however, are stable and must match exactly.

## 1. Local testing in Xcode

1. Open `Stepper.xcodeproj` in Xcode.
2. Product → Scheme → Edit Scheme… → **Run** → **Options** tab.
3. Under **StoreKit Configuration**, choose `Stepper/Stepper.storekit`.
4. Run the app in Simulator. The paywall should display three plans
   (Monthly, Yearly, Lifetime) with prices loaded from the local config.
5. Tap a plan → ИНИЦИАЛИЗИРОВАТЬ → confirm in the synthetic purchase
   sheet. The app should flip into Premium and surface the welcome
   overlay.
6. Settings → Premium → **Restore Purchases** should report
   "Premium active" once a purchase exists.

To reset state during testing: Xcode → Debug → StoreKit → **Manage
Transactions…** → Delete All.

## 2. Products to create in App Store Connect

Bundle ID: `com.borisdev.Stepper`. Subscription group reference name:
`footstepeR Premium`.

| Product ID                                 | Type                       | Price (placeholder) | Trial   |
|--------------------------------------------|----------------------------|---------------------|---------|
| `com.borisdev.Stepper.premium.monthly`     | Auto-Renewable Monthly     | $4.99               | 1 week  |
| `com.borisdev.Stepper.premium.yearly`      | Auto-Renewable Yearly      | $39.99              | 1 week  |
| `com.borisdev.Stepper.premium.lifetime`    | Non-Consumable             | $29.99              | —       |

Localisations to add for each product (matches `Localizable.xcstrings`):

- **EN (US)**
  - Monthly — *Premium — Monthly* — "Auto-renewing monthly. 1-week free trial."
  - Yearly — *Premium — Yearly* — "Auto-renewing yearly. Save 33%. 1-week free trial."
  - Lifetime — *footstepeR Premium — Lifetime* — "One-time payment, all premium features forever."
- **RU (RU)**
  - Monthly — *Premium — Месяц* — "Автопродление каждый месяц. Неделя бесплатно."
  - Yearly — *Premium — Год* — "Автопродление каждый год. Скидка 33%. Неделя бесплатно."
  - Lifetime — *footstepeR Premium — Навсегда* — "Разовая оплата, все премиум-функции навсегда."

Subscription group display copy:
- EN: "Unlock unlimited AI Coach, advanced biomechanics, and route history beyond 30 days."
- RU: "Безлимит AI Coach, продвинутая биомеханика и история маршрутов глубже 30 дней."

## 3. Submission checklist (App Review)

- [ ] All three product IDs created and **Ready to Submit** in ASC.
- [ ] Subscription group has at least one localised "App Store
      Promotion" image (required if you ever opt into ASC promo slots).
- [ ] Privacy Policy URL on the app record points at our GitHub Pages
      site (already wired in PR #1).
- [ ] Review notes mention test instructions (e.g. "Sign in with the
      provided sandbox Apple ID, tap any plan; sandbox purchase will
      complete with no charge.").
- [ ] Sandbox tester account created in
      App Store Connect → Users and Access → Sandbox Testers.

## 4. How the wiring works in code

- `Stepper/SubscriptionManager.swift` is the single source of truth for
  `products`, `isPremium`, `purchase()`, `restore()`. It listens to
  `Transaction.updates` from launch so out-of-band events (Ask-to-Buy,
  family sharing approvals) are picked up automatically.
- `PremiumPaywallScreen` reads `subscriptions.products` and renders one
  cyberpunk-styled plan row per product via `PaywallPlanPresenter`.
- `SettingsView.subscriptionSection` shows current entitlement status
  and a Restore Purchases button calling `subscriptions.restore()`.

If you ever want to add a new tier (e.g. Quarterly), append a new case
to `SubscriptionManager.ProductID`, mirror it in `Stepper.storekit`, and
extend `PaywallPlanPresenter.plan(for:)` with copy.
