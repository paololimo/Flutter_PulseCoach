# v2 Cloud / Store Platform-Config Checklist (E16R-3)

**Owner:** Paolo + Winston (Architect) · **Created:** 2026-06-22 · **Action item:** E16R-3 (Epic 16 retro)

**Purpose.** Epic 16 introduced cloud auth/backup whose flows can only be verified end-to-end with manual platform/dashboard configuration that is "invisible until needed" — it is not in the repo, not automatable, and was the reason real OAuth/backup/delete/export stayed **N/A** at the Epic 16 on-device gate. Epic 17 (RevenueCat IAP) adds the same class of store-side config. This is the single living checklist that turns those N/A items into PASS.

> **How to use:** before an epic whose ACs touch cloud/store, walk the relevant section, tick each item, and record where the secret lives. A build that passes the `--dart-define` / env-var row can exercise the real flow on-device.

---

## 0. Build-time secrets (how to inject)

The app reads cloud creds via `String.fromEnvironment` — a plain `flutter build apk --debug` has **empty** creds (which is why the free core must, and does, survive empty creds — 16.1-AC4). To verify real flows on device:

```
flutter run -d <device> \
  --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<publishable/anon key> \
  --dart-define=REVENUECAT_API_KEY_ANDROID=<rc key>   # Epic 17
```

- [ ] Secrets are passed via `--dart-define` (or a `--dart-define-from-file` JSON) — **never** committed.
- [ ] A local `dart-defines.json` (gitignored) holds the dev values; its key names are documented here.
- [ ] CI injects the same keys from secret store (for signed/release verification builds).

---

## 1. Supabase (Auth + Storage backend) — Epic 16

- [ ] Project created in the **EU region (`eu-central-1`, Frankfurt)** — region is set in the **dashboard**, not in `supabase/config.toml` (the CLI config has no functional region field; `config.toml` only carries a placeholder comment). (ARCH17, NFR36)
- [ ] `SUPABASE_URL` + anon/**publishable** key copied into the dev `dart-defines` (supabase_flutter 2.15.0 → `Supabase.initialize(publishableKey:)`, not `anonKey:`).
- [ ] Migration `0001_profiles_auth.sql` applied (profiles table + RLS) — `supabase db push`.
- [ ] Edge Functions deployed: `delete_account_cascade`, `export_user_data` (`supabase functions deploy <name>`). Without these, 16.4 Delete/Export 500s.
- [ ] Storage bucket for E2E backup blobs exists with RLS restricting rows to the owner (16.3 uploads ciphertext + non-secret metadata only).
- **Verify:** sign in with email on device → backup → reinstall → restore round-trip; delete account → returns to onboarding, local Drift intact.

## 2. Sign in with Apple — Epic 16 (Story 16.2, Task 6.3)

- [ ] **Apple Developer Portal:** enable the **Sign in with Apple** capability on the App ID (manual — not automatable).
- [ ] Service ID + return URL registered, pointing at the Supabase Apple provider callback.
- [ ] Supabase dashboard → Auth → Providers → **Apple** enabled with the Service ID / key.
- **Verify:** native Apple ID sheet completes → Supabase session created → `AuthBloc` → `authenticated`; refresh token in `flutter_secure_storage`.

## 3. Sign in with Google — Epic 16 (Story 16.2, Task 7.4)

- [ ] `android/app/google-services.json` present. **Secret hygiene:** if it carries restricted values, gitignore it and provide via CI; otherwise document why it is safe to commit.
- [ ] `android/app/build.gradle(.kts)`: `minSdkVersion ≥ 21` (Google Sign-In requirement — already satisfied).
- [ ] iOS `Runner/Info.plist` `CFBundleURLSchemes` uses `$(GOOGLE_REVERSED_CLIENT_ID)`; the real `REVERSED_CLIENT_ID` from `GoogleService-Info.plist` is injected via Xcode build setting / CI env var.
- [ ] Supabase dashboard → Auth → Providers → **Google** → enabled + **Redirect URLs** configured.
- **Verify:** Google flow completes → same `authenticated` state.

## 4. Compliance toggles — Epic 16

- [ ] NFR37 age-gate: sign-up requires the **age ≥ 16** confirmation checkbox (per-market exact minimum is a tracked business open item; impl uses 16).

## 5. RevenueCat IAP — Epic 17 (forward-looking, Story 17.1)

- [ ] `purchases_flutter` added; `Purchases.configure(...)` called with the **per-platform** RevenueCat API key (`REVENUECAT_API_KEY_ANDROID` / `_IOS`), singleton in `lib/features/subscription/` (ARCH20).
- [ ] **App Store Connect:** auto-renewable subscription product(s) created + in "Ready to Submit"; StoreKit config for local testing.
- [ ] **Google Play Console:** subscription product(s) created; license testers added for sandbox purchase.
- [ ] RevenueCat dashboard: products mapped to an **entitlement** (e.g. `pro`); offerings configured.
- [ ] `EntitlementGate` (`lib/core/cloud/entitlement_gate.dart`) — **build this first in 17.1** (Epic 16's goal named an "EntitlementGate skeleton" but only `AuthBloc` shipped; the gate does not exist yet).
- **Verify:** sandbox purchase → `EntitlementGate.check(Feature.x)` returns `pro`; restore purchases re-grants on reinstall.

---

## Status log

| Date | Section | Note |
|---|---|---|
| 2026-06-22 | created | E16R-3 deliverable produced from Epic 16 retro; closes the action item. Sections 1–4 reflect Epic 16 completion-note manual steps; section 5 pre-stages Epic 17. None of the live values are stored here — only what to configure and where. |
