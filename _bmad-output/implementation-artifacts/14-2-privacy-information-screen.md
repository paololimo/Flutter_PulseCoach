# Story 14.2: Privacy Information Screen

Status: done

## Story

As a user,
I want to read a clear privacy information screen,
So that I can verify exactly what data is collected, stored, and shared.

## Acceptance Criteria

**AC1 — Privacy screen explains all data practices (FR49, NFR7, NFR12):**
Given the user navigates to Privacy from the drawer
When the screen renders
Then it clearly explains:
- data stored on-device only (NFR7)
- no external transmission for personalization
- Health API data usage (NFR9)
- location data is city-level only (NFR8)
- GDPR compliance statement (NFR12)

**AC2 — No references to external accounts or servers (FR49):**
Given the privacy screen is displayed
When inspected
Then it makes no reference to external accounts, servers, or data sharing for personalization purposes

## Tasks / Subtasks

- [x] Task 1: Add ARB keys for privacy content (AC1)
  - [x] 1.1 Add 9 keys to `app_it.arb` (page title + 4 section titles + 4 section bodies)
  - [x] 1.2 Add the same 9 keys to `app_en.arb`
  - [x] 1.3 Run `flutter pub get` to regenerate `app_localizations*.dart`

- [x] Task 2: Implement `PrivacyPage` (AC1, AC2)
  - [x] 2.1 Replace the stub with a `Scaffold` + `AppBar` + `ListView`
  - [x] 2.2 Add 4 privacy sections using localized strings and theme tokens (no hardcoded text or colors)
  - [x] 2.3 Each section: `Text(title, style: titleSmall)` + `SizedBox(height: 8)` + `Text(body)` + `SizedBox(height: 24)`

- [x] Task 3: Add widget tests
  - [x] 3.1 `14.2-WIDGET-001`: PrivacyPage renders the on-device data section heading
  - [x] 3.2 `14.2-WIDGET-002`: PrivacyPage renders the Health API section heading
  - [x] 3.3 `14.2-WIDGET-003`: PrivacyPage renders the location section heading
  - [x] 3.4 `14.2-WIDGET-004`: PrivacyPage renders the GDPR compliance section heading
  - [x] 3.5 `14.2-WIDGET-005`: PrivacyPage AppBar title matches `privacyPageTitle` l10n key

- [x] Task 4: Verify
  - [x] 4.1 Run `flutter test` from `pulse_coach/`. Target: ≥ 822 + 5 new = ≥ 827 total. All existing tests remain green.
  - [x] 4.2 Run `flutter analyze` from `pulse_coach/`. Must be 0 issues.

## Dev Notes

### What Is Already In Place (Do NOT Reinvent)

- **`PrivacyPage` stub** exists at `pulse_coach/lib/features/settings/presentation/pages/privacy_page.dart` — currently a bare `Scaffold` with `Center(child: Text('Privacy — Story 14.x'))`. **This is the UPDATE target.** Do NOT create a new file.
- **Route `/privacy`** is already registered in `lib/core/routing/app_router.dart` (`AppRoutes.privacy = '/privacy'`, line 35) and wired to `PrivacyPage` (line 105). **No routing changes needed.**
- **Drawer entry** "Privacy" (`drawerPrivacy` ARB key) already navigates to `/privacy` from the drawer. **No drawer changes needed.**
- **ARB pipeline** is fully wired (Epic 7.5): source files are `lib/l10n/app/app_it.arb` and `lib/l10n/app/app_en.arb`; generated files are `.gitignore`d and regenerated on `flutter pub get`.
- **`SharedPreferences`** and `SettingsModule` DI are in place from Story 14.1 — no DI changes needed for this story.
- **`AppLocalizations`** import path: `import 'package:pulse_coach/l10n/app_localizations.dart';` (generated, not source).

### PrivacyPage — Current Stub (to Replace)

```dart
// pulse_coach/lib/features/settings/presentation/pages/privacy_page.dart
import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: const Center(child: Text('Privacy — Story 14.x')),
    );
  }
}
```

### PrivacyPage — Target Implementation Shape

```dart
import 'package:flutter/material.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyPageTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PrivacySection(
            title: l10n.privacyOnDeviceTitle,
            body: l10n.privacyOnDeviceBody,
            textTheme: textTheme,
          ),
          _PrivacySection(
            title: l10n.privacyHealthApiTitle,
            body: l10n.privacyHealthApiBody,
            textTheme: textTheme,
          ),
          _PrivacySection(
            title: l10n.privacyLocationTitle,
            body: l10n.privacyLocationBody,
            textTheme: textTheme,
          ),
          _PrivacySection(
            title: l10n.privacyGdprTitle,
            body: l10n.privacyGdprBody,
            textTheme: textTheme,
          ),
        ],
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({
    required this.title,
    required this.body,
    required this.textTheme,
  });

  final String title;
  final String body;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(body, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
```

Key points:
- `_PrivacySection` is a private helper within the same file — no need for a separate `privacy_info.dart` widget file for this simple layout.
- No `Bloc`, no loading state, no `shimmer` — all content is static (compile-time strings from ARB).
- All text styles via `textTheme` (theme tokens) — never hardcoded.
- `AppLocalizations.of(context)!` is safe here because `MaterialApp.router` in `app.dart` already provides the localization delegates globally.

### ARB Keys — What to Add

Add 9 keys to **both** `pulse_coach/lib/l10n/app/app_it.arb` and `pulse_coach/lib/l10n/app/app_en.arb`.

**Italian additions (`app_it.arb`):**
```json
"privacyPageTitle": "Privacy",
"privacyOnDeviceTitle": "Dati solo sul dispositivo",
"privacyOnDeviceBody": "Tutti i dati personali e di allenamento sono conservati esclusivamente sul tuo dispositivo. PulseCoach non trasmette dati a server esterni per la personalizzazione.",
"privacyHealthApiTitle": "API Salute",
"privacyHealthApiBody": "PulseCoach può leggere la frequenza cardiaca e il conteggio dei passi dalle API Salute del dispositivo (HealthKit / Health Connect), se il permesso è concesso. Questi dati non lasciano mai il dispositivo.",
"privacyLocationTitle": "Posizione",
"privacyLocationBody": "PulseCoach usa solo la posizione a livello di città (coordinate approssimate) per ottenere informazioni meteo. Non vengono memorizzate o trasmesse coordinate GPS precise.",
"privacyGdprTitle": "Conformità GDPR",
"privacyGdprBody": "I dati biometrici sono classificati come dati sensibili ai sensi dell'Art. 9 del GDPR. PulseCoach li elabora localmente con il tuo esplicito consenso e non li condivide con terze parti."
```

**English additions (`app_en.arb`):**
```json
"privacyPageTitle": "Privacy",
"privacyOnDeviceTitle": "Data stays on your device",
"privacyOnDeviceBody": "All personal and workout data is stored exclusively on your device. PulseCoach does not transmit data to external servers for personalisation.",
"privacyHealthApiTitle": "Health API",
"privacyHealthApiBody": "PulseCoach can read heart rate and step count from the device Health API (HealthKit / Health Connect), if permission is granted. This data never leaves your device.",
"privacyLocationTitle": "Location",
"privacyLocationBody": "PulseCoach uses only city-level location (approximate coordinates) to fetch weather information. No precise GPS coordinates are stored or transmitted.",
"privacyGdprTitle": "GDPR Compliance",
"privacyGdprBody": "Biometric data is classified as sensitive data under GDPR Art. 9. PulseCoach processes it locally with your explicit consent and does not share it with third parties."
```

Add these at the end of each file, before the closing `}`.

### Widget Tests — Pattern

Create `pulse_coach/test/widget/privacy_page_test.dart`. Model after `settings_page_test.dart` from Story 14.1. No `ThemeCubit` or `BlocProvider` needed — `PrivacyPage` has no Bloc dependency.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/features/settings/presentation/pages/privacy_page.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

Widget _buildPrivacyPage() => MaterialApp(
      home: const PrivacyPage(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('it'),
    );
```

The 5 tests (`14.2-WIDGET-001` through `14.2-WIDGET-005`) find the Italian localized strings from the ARB. For example:
- `14.2-WIDGET-001`: `expect(find.text('Dati solo sul dispositivo'), findsOneWidget)`
- `14.2-WIDGET-005`: `expect(find.text('Privacy'), findsWidgets)` — AppBar title is 'Privacy'

### Architecture Constraints (Do Not Violate)

- No `CircularProgressIndicator` — this is a static page; no loading state needed.
- No hardcoded colors, text, or styles — all via `Theme.of(context)` and `AppLocalizations`.
- `PrivacyPage` must NOT reference any Bloc, use case, or repository — it is presentation-only static content.
- `injection.config.dart` is GENERATED — do NOT edit. This story adds no new DI registrations.
- Generated `app_localizations*.dart` are `.gitignore`d — run `flutter pub get` after ARB changes.
- `flutter analyze` must remain at 0 issues after implementation.

### Privacy Content Must Cover (AC1 Checklist)

| Requirement | ARB key | Content |
|---|---|---|
| Data stored on-device only | `privacyOnDeviceBody` | "stored exclusively on your device" |
| No external transmission for personalization | `privacyOnDeviceBody` | "does not transmit data to external servers for personalisation" |
| Health API data usage | `privacyHealthApiBody` | HealthKit / Health Connect; data stays on device |
| Location is city-level only | `privacyLocationBody` | "city-level location (approximate coordinates)" |
| GDPR compliance statement | `privacyGdprBody` | "GDPR Art. 9 … processed locally with your explicit consent" |

### Current Test Baseline

As of Story 14.1 done (2026-06-05): `flutter test` passes with **822/822** tests.

New tests this story: 5 widget tests.
Target after story: ≥ **827** tests.

### File Changes Summary

**MODIFY:**
- `pulse_coach/lib/features/settings/presentation/pages/privacy_page.dart` — full implementation replacing stub
- `pulse_coach/lib/l10n/app/app_it.arb` — 9 new keys
- `pulse_coach/lib/l10n/app/app_en.arb` — 9 new keys

**CREATE:**
- `pulse_coach/test/widget/privacy_page_test.dart` — 5 widget tests

**REGENERATED (do not manually edit):**
- `pulse_coach/lib/l10n/app_localizations.dart` + `app_localizations_it.dart` + `app_localizations_en.dart` — via `flutter pub get`

### References

- Story ACs: `_bmad-output/planning-artifacts/epics.md` §Epic 14, Story 14.2
- FR49, NFR7, NFR8, NFR9, NFR12: `_bmad-output/planning-artifacts/prd.md`
- Architecture widget list: `_bmad-output/planning-artifacts/architecture.md` §settings/presentation/widgets/ (`privacy_info.dart` listed but not a binding scope item for this story)
- PrivacyPage stub: `pulse_coach/lib/features/settings/presentation/pages/privacy_page.dart`
- Route: `pulse_coach/lib/core/routing/app_router.dart` (line 35: `privacy = '/privacy'`; line 105: `GoRoute` to `PrivacyPage`)
- ARB sources: `pulse_coach/lib/l10n/app/app_it.arb`, `pulse_coach/lib/l10n/app/app_en.arb`
- Settings page (same l10n pattern): `pulse_coach/lib/features/settings/presentation/pages/settings_page.dart`
- Settings page tests (widget test pattern): `pulse_coach/test/widget/settings_page_test.dart`
- Previous story (14.1): `_bmad-output/implementation-artifacts/14-1-theme-toggle-dark-light-system.md`

### Review Findings

_Code review 2026-06-05 (Blind Hunter + Edge Case Hunter + Acceptance Auditor). AC1, AC2 and all architecture constraints PASS. 6 findings dismissed as noise/by-design/handled. No decision-needed, no deferred items._

- [x] [Review][Patch] `14.2-WIDGET-005` assertion uses `findsWidgets` and is not scoped to the AppBar — does not actually verify the AppBar title binding [pulse_coach/test/widget/privacy_page_test.dart:202] — FIXED: now scoped via `find.descendant(of: AppBar, ...)` + `findsOneWidget`
- [x] [Review][Patch] No test asserts section **body** text (only headings) — a swapped `title:`/`body:` wiring would go uncaught [pulse_coach/test/widget/privacy_page_test.dart:168] — FIXED: added `14.2-WIDGET-006` asserting all 4 section bodies render

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- `flutter test test/widget/privacy_page_test.dart` (RED): failed 4 section-heading expectations against the stub, confirming test coverage.
- `flutter pub get`: completed successfully after ARB updates and regenerated ignored l10n outputs.
- `flutter test test/widget/privacy_page_test.dart`: 5/5 tests passed.
- `flutter test test/widget/privacy_page_test.dart test/widget/pages_smoke_test.dart`: 15/15 tests passed after updating the existing PrivacyPage smoke test for l10n.
- `flutter analyze`: initially reported one `prefer_const_constructors` info in the new widget test; fixed.
- `flutter analyze`: no issues found.
- `flutter test`: final full regression passed, 827/827 tests.

### Completion Notes List

- Added localized privacy content in Italian and English covering on-device storage, no personalization transmission, Health API use, city-level location, and GDPR Art. 9 local processing/consent.
- Replaced the PrivacyPage stub with a static localized Scaffold/AppBar/ListView implementation using theme text tokens only.
- Added 5 story-specific widget tests for the required headings and localized AppBar title.
- Updated the existing PrivacyPage smoke test to pump with localization delegates and assert the implemented content instead of the removed stub text.

### File List

- `_bmad-output/implementation-artifacts/14-2-privacy-information-screen.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `pulse_coach/lib/features/settings/presentation/pages/privacy_page.dart`
- `pulse_coach/lib/l10n/app/app_en.arb`
- `pulse_coach/lib/l10n/app/app_it.arb`
- `pulse_coach/test/widget/pages_smoke_test.dart`
- `pulse_coach/test/widget/privacy_page_test.dart`

### Change Log

- 2026-06-05: Implemented Story 14.2 privacy information screen with localized ARB content, static themed PrivacyPage UI, 5 widget tests, updated smoke regression, and verified `flutter test` 827/827 plus `flutter analyze` 0 issues. Status: review.
