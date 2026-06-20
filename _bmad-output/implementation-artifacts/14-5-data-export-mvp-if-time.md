# Story 14.5: Data Export [MVP-if-time]

Status: done

## Story

As a power user,
I want to export my session history and AI decisions as CSV or JSON,
So that I can analyze my data in external tools or maintain a personal record.

## Acceptance Criteria

**AC1 — Export Data entry in Settings:**
Given the user opens the Settings screen
When the screen renders
Then a "Dati" section is visible with an "Esporta dati" ListTile

**AC2 — Bottom sheet with format options (FR52):**
Given the user taps "Esporta dati"
When the bottom sheet opens
Then two buttons are presented: "JSON" and "CSV"

**AC3 — JSON export via OS share sheet:**
Given the user taps "JSON" in the bottom sheet
When the export runs
Then a JSON file is generated containing:
- `sessions`: all session rows with date, type, duration, rpe (nullable), abandoned flag
- `weeklySummaries`: per-Monday-week aggregates (weekOf ISO date, completedSessions, abandonedSessions, totalMinutes)
- `aiDecisions`: bandit decision history (decidedAt, armKey, rpeValue)
And the file is shared via the OS share sheet

**AC4 — CSV export via OS share sheet:**
Given the user taps "CSV"
When the export runs
Then a CSV file with header `date,type,duration_minutes,rpe,abandoned` and one row per session is generated and shared via the OS share sheet

**AC5 — Loading state during export:**
Given an export is in progress
When either button is tapped
Then a CircularProgressIndicator replaces both buttons until the OS share sheet is invoked (or an error occurs)

**AC6 — Error state:**
Given the export fails (e.g. file I/O error)
When the error is caught
Then a SnackBar shows "Errore durante l'esportazione" and the bottom sheet buttons return to their normal state

## Tasks / Subtasks

- [x] Task 1: Add dependencies to pubspec.yaml
  - [x] 1.1 Add `share_plus: ^10.0.0` under `dependencies` in `pulse_coach/pubspec.yaml`
  - [x] 1.2 Add `path_provider: ^2.1.0` under `dependencies` in `pulse_coach/pubspec.yaml`
  - [x] 1.3 Run `flutter pub get` from `pulse_coach/` — verify both packages resolve cleanly
  - [x] 1.4 Add Android permissions if required: `share_plus` needs no special manifest permissions for file sharing via the share intent; `path_provider` writes to the temp directory which requires no special Android permission (uses cache dir)

- [x] Task 2: Add ARB keys
  - [x] 2.1 Add to `pulse_coach/lib/l10n/app/app_it.arb`:
    - `dataExportNavSection`: "Dati"
    - `dataExportTile`: "Esporta dati"
    - `dataExportSheetTitle`: "Esporta dati"
    - `dataExportJson`: "JSON"
    - `dataExportCsv`: "CSV"
    - `dataExportError`: "Errore durante l'esportazione"
  - [x] 2.2 Add the same keys (English values) to `pulse_coach/lib/l10n/app/app_en.arb`:
    - `dataExportNavSection`: "Data"
    - `dataExportTile`: "Export data"
    - `dataExportSheetTitle`: "Export data"
    - `dataExportJson`: "JSON"
    - `dataExportCsv`: "CSV"
    - `dataExportError`: "Export failed"
  - [x] 2.3 Run `flutter pub get` from `pulse_coach/` to regenerate `app_localizations*.dart`

- [x] Task 3: Create `DataExportService`
  - [x] 3.1 Create `pulse_coach/lib/features/settings/data/services/data_export_service.dart`
  - [x] 3.2 Annotate `@injectable`; constructor accepts `ProgressLocalDataSource` and `AiDecisionLogRepository`:
    ```dart
    @injectable
    class DataExportService {
      DataExportService(this._progressDataSource, this._decisionLogRepository);
      final ProgressLocalDataSource _progressDataSource;
      final AiDecisionLogRepository _decisionLogRepository;
      Future<void> exportJson() async { ... }
      Future<void> exportCsv() async { ... }
    }
    ```
  - [x] 3.3 Implement `exportJson()`:
    - Call `_progressDataSource.getSessionHistory()` — returns `List<SessionHistoryEntry>`
    - Call `_decisionLogRepository.getDecisions()` — returns `List<AiDecisionRecord>`
    - Build `sessions` list from `SessionHistoryEntry` objects (use `completedAt.toIso8601String()`, `sessionType`, `durationMinutes`, `rpeValue`, `abandoned`)
    - Build `weeklySummaries` by grouping sessions by Monday-week start (use `_mondayOf()` helper, same algorithm as in `ProgressLocalDataSource`):
      - weekOf: `DateFormat('yyyy-MM-dd').format(weekStart)` — requires `intl` (already in pubspec)
      - completedSessions: count of `!abandoned` entries in that week
      - abandonedSessions: count of `abandoned` entries
      - totalMinutes: sum of `durationMinutes` for completed + `(elapsedSeconds ?? 0) ~/ 60` for abandoned
    - Build `aiDecisions` from `AiDecisionRecord` objects
    - Encode to `jsonEncode(payload)` (dart:convert, no extra package)
    - Write to temp file via `path_provider`:
      ```dart
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/pulsecoach_export_${_timestamp()}.json');
      await file.writeAsString(encoded);
      ```
    - Share via `share_plus`: `await Share.shareXFiles([XFile(file.path, name: 'pulsecoach_export.json')])`
  - [x] 3.4 Implement `exportCsv()`:
    - Call `_progressDataSource.getSessionHistory()`
    - Build CSV string: header row + one row per `SessionHistoryEntry`
    - CSV row format: `date,type,duration_minutes,rpe,abandoned` where date = `completedAt.toIso8601String()`, rpe = `rpeValue ?? ''`
    - Write to temp file: `pulsecoach_export_${_timestamp()}.csv` with MIME type `text/csv`
    - Share via `Share.shareXFiles([XFile(file.path, name: 'pulsecoach_export.csv', mimeType: 'text/csv')])`
  - [x] 3.5 `_timestamp()` helper: `DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())` — intl already available
  - [x] 3.6 `_mondayOf(DateTime date)` helper (same algorithm as `ProgressLocalDataSource._mondayOf`):
    ```dart
    DateTime _mondayOf(DateTime date) {
      final utc = date.toUtc();
      return DateTime.utc(utc.year, utc.month, utc.day - (utc.weekday - 1));
    }
    ```
  - [x] 3.7 Run `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/` to regenerate `injection.config.dart`

- [x] Task 4: Create `DataExportState` and `DataExportCubit`
  - [x] 4.1 Create `pulse_coach/lib/features/settings/presentation/bloc/data_export_state.dart`:
    ```dart
    import 'package:equatable/equatable.dart';

    class DataExportState extends Equatable {
      const DataExportState({this.isExporting = false, this.errorMessage});
      final bool isExporting;
      final String? errorMessage;

      @override
      List<Object?> get props => [isExporting, errorMessage];
    }
    ```
  - [x] 4.2 Create `pulse_coach/lib/features/settings/presentation/bloc/data_export_cubit.dart`:
    ```dart
    @injectable
    class DataExportCubit extends Cubit<DataExportState> {
      DataExportCubit(this._exportService) : super(const DataExportState());
      final DataExportService _exportService;

      Future<void> exportJson() async {
        emit(const DataExportState(isExporting: true));
        try {
          await _exportService.exportJson();
          emit(const DataExportState(isExporting: false));
        } catch (_) {
          emit(const DataExportState(isExporting: false, errorMessage: 'export_failed'));
        }
      }

      Future<void> exportCsv() async {
        emit(const DataExportState(isExporting: true));
        try {
          await _exportService.exportCsv();
          emit(const DataExportState(isExporting: false));
        } catch (_) {
          emit(const DataExportState(isExporting: false, errorMessage: 'export_failed'));
        }
      }
    }
    ```
  - [x] 4.3 Annotate `@injectable`; run `dart run build_runner build --delete-conflicting-outputs` after

- [x] Task 5: Update `SettingsPage` to add the export entry and bottom sheet
  - [x] 5.1 Add the "Dati" section and "Esporta dati" tile to `SettingsPage` (`pulse_coach/lib/features/settings/presentation/pages/settings_page.dart`):
    - After the existing "Dispositivo" section, add:
      ```dart
      const SizedBox(height: 24),
      Text(l10n.dataExportNavSection, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.dataExportTile),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showExportSheet(context),
      ),
      ```
    - Add `_showExportSheet(BuildContext context)` method on the widget. Since `SettingsPage` is `StatelessWidget`, this must be a top-level or static method:
      ```dart
      void _showExportSheet(BuildContext context) {
        showModalBottomSheet(
          context: context,
          builder: (_) => BlocProvider(
            create: (_) => getIt<DataExportCubit>(),
            child: _ExportBottomSheet(),
          ),
        );
      }
      ```
    - Add import: `package:pulse_coach/features/settings/presentation/bloc/data_export_cubit.dart` and `data_export_state.dart`
  - [x] 5.2 Create the `_ExportBottomSheet` private widget inside `settings_page.dart` (same file, after `SettingsPage`):
    ```dart
    class _ExportBottomSheet extends StatelessWidget {
      @override
      Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        return BlocConsumer<DataExportCubit, DataExportState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.dataExportError)),
              );
            }
          },
          builder: (context, state) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.dataExportSheetTitle,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    if (state.isExporting)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      OutlinedButton(
                        onPressed: () => context.read<DataExportCubit>().exportJson(),
                        child: Text(l10n.dataExportJson),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => context.read<DataExportCubit>().exportCsv(),
                        child: Text(l10n.dataExportCsv),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      }
    }
    ```
  - [x] 5.3 Add `import 'package:pulse_coach/core/di/injection.dart';` to `settings_page.dart` (needed for `getIt`)

- [x] Task 6: Add tests
  - [x] 6.1 Create `pulse_coach/test/bloc/data_export_cubit_test.dart`:
    ```dart
    @GenerateMocks([DataExportService])
    void main() { ... }
    ```
    - [x] `14.5-CUBIT-001`: `exportJson()` emits `isExporting: true` then `isExporting: false` on success
    - [x] `14.5-CUBIT-002`: `exportCsv()` emits `isExporting: true` then `isExporting: false` on success
    - [x] `14.5-CUBIT-003`: `exportJson()` emits `isExporting: true` then `errorMessage != null` when service throws
    - [x] `14.5-CUBIT-004`: `exportCsv()` emits `isExporting: true` then `errorMessage != null` when service throws
  - [x] 6.2 Run `dart run build_runner build --delete-conflicting-outputs` to generate `data_export_cubit_test.mocks.dart`

- [x] Task 7: Verify
  - [x] 7.1 Run `flutter test` from `pulse_coach/`. Target: 844 + 4 = **848 total**. All existing tests green.
  - [x] 7.2 Run `flutter analyze` from `pulse_coach/`. Must be **0 issues**.

## Dev Notes

### What Is Already In Place (Do NOT Reinvent)

- **`ProgressLocalDataSource`** at `pulse_coach/lib/features/progress/data/datasources/progress_local_data_source.dart` — `getSessionHistory()` returns `List<SessionHistoryEntry>` with all fields needed for both CSV and JSON. Already handles the SessionLogs → DailyPlan (planJson decode) → RpeFeedback join. **Reuse this directly** — do not re-implement the join in `DataExportService`.
- **`SessionHistoryEntry`** at `pulse_coach/lib/features/progress/domain/entities/session_history_entry.dart` — freezed class with: `sessionLogId`, `completedAt`, `sessionType`, `durationMinutes`, `abandoned`, `rpeValue` (nullable), `elapsedSeconds` (nullable).
- **`AiDecisionLogRepository`** at `pulse_coach/lib/features/settings/data/repositories/ai_decision_log_repository.dart` — `getDecisions()` returns `List<AiDecisionRecord>`. Each record has `decidedAt`, `armKey`, `rpeValue`, `stateVector` (always null for now). **Reuse directly.**
- **`_mondayOf()` algorithm** is in `ProgressLocalDataSource` (lines ~116-121). Copy the same private helper into `DataExportService` — same 6-line body, no import needed.
- **`intl` package** is already in `pubspec.yaml` (line 63: `intl: ^0.20.2`). Use `package:intl/intl.dart` for `DateFormat` in `_timestamp()`.
- **`dart:convert`** is a Dart SDK library — no package needed for `jsonEncode`.
- **`dart:io`** is available on mobile — `File` is in `dart:io`.
- **DI pattern**: `@injectable` on the service and cubit; run `flutter pub run build_runner build --delete-conflicting-outputs`. Both `ProgressLocalDataSource` (`@lazySingleton`) and `AiDecisionLogRepository` (`@injectable`) are already in the DI graph and will be injected automatically.
- **SettingsPage pattern**: uses `Theme.of(context).textTheme.titleSmall` for section headers, `ListTile(contentPadding: EdgeInsets.zero, ...)` for nav tiles — match this exactly.
- **getIt import** already used in `app_router.dart`. You need `import 'package:pulse_coach/core/di/injection.dart';` in `settings_page.dart`.

### New Dependencies — share_plus and path_provider

Add these to `pubspec.yaml` under `dependencies`:

```yaml
  share_plus: ^10.0.0
  path_provider: ^2.1.0
```

**share_plus API (v10.x):**
```dart
import 'package:share_plus/share_plus.dart';
// Share a file:
await Share.shareXFiles(
  [XFile(file.path, name: 'pulsecoach_export.json')],
);
// With MIME type for CSV:
await Share.shareXFiles(
  [XFile(file.path, name: 'pulsecoach_export.csv', mimeType: 'text/csv')],
);
```

**path_provider API:**
```dart
import 'package:path_provider/path_provider.dart';
final dir = await getTemporaryDirectory();
// dir.path is the OS temp/cache directory — writable, no permissions needed
```

No Android manifest changes are needed: `share_plus` uses the `android.intent.action.SEND` intent which is a system API, and `path_provider` writes to the app's cache directory.

**iOS considerations**: `share_plus` on iOS invokes `UIActivityViewController` — no special entitlements needed for basic file sharing.

### DI Topology

```
ProgressLocalDataSource(@lazySingleton) ← SessionLogsDao, DailyPlansDao, RpeFeedbackDao
AiDecisionLogRepository(@injectable) ← RpeFeedbackDao, SessionLogsDao, DailyPlansDao

DataExportService(@injectable) ← ProgressLocalDataSource, AiDecisionLogRepository
DataExportCubit(@injectable) ← DataExportService
```

`DataExportCubit` is `@injectable` (not `@singleton` or `@lazySingleton`) because it's created fresh on each bottom sheet open via `BlocProvider(create: (_) => getIt<DataExportCubit>())`. This is the same lifecycle as `AiDecisionLogCubit` and `DeviceSettingsCubit`.

### JSON Export Shape

```json
{
  "exportedAt": "2026-06-05T12:00:00.000Z",
  "sessions": [
    {
      "date": "2026-06-04T08:30:00.000Z",
      "type": "mobility",
      "durationMinutes": 10,
      "rpe": 6,
      "abandoned": false
    }
  ],
  "weeklySummaries": [
    {
      "weekOf": "2026-06-01",
      "completedSessions": 3,
      "abandonedSessions": 0,
      "totalMinutes": 45
    }
  ],
  "aiDecisions": [
    {
      "decidedAt": "2026-06-04T08:30:00.000Z",
      "armKey": "mobility_medium",
      "rpeValue": 6
    }
  ]
}
```

Add `"exportedAt": DateTime.now().toUtc().toIso8601String()` as the top-level metadata field.

### CSV Export Shape

```csv
date,type,duration_minutes,rpe,abandoned
2026-06-04T08:30:00.000Z,mobility,10,6,false
2026-06-03T09:15:00.000Z,cardio,20,,true
```

RPE column: `rpeValue?.toString() ?? ''` — empty string for sessions without RPE.

CSV escaping: fields in this export are safe (ISO date strings, type names from a known enum, integers, booleans) — no CSV escaping needed. Do NOT add a CSV escaping utility; it would be premature for this data shape.

### Bottom Sheet Placement — SettingsPage Structure After This Story

```
Scaffold > AppBar "Impostazioni"
└── ListView (padding: 16)
    ├── Text "Tema" (titleSmall)
    ├── SegmentedButton [dark | light | system]
    ├── SizedBox(height: 24)
    ├── Text "Dispositivo" (titleSmall)
    ├── ListTile "Dispositivo e Sync" → push /device-settings
    ├── SizedBox(height: 24)          ← NEW
    ├── Text "Dati" (titleSmall)      ← NEW
    ├── SizedBox(height: 8)           ← NEW
    └── ListTile "Esporta dati" → showModalBottomSheet  ← NEW
```

### Test Patterns to Follow

Use `bloc_test` with `blocTest<DataExportCubit, DataExportState>()`. Mock `DataExportService` with `@GenerateMocks([DataExportService])`. The service has two methods: `exportJson()` and `exportCsv()`, both `Future<void>`. Mock them as `thenAnswer((_) async {})` for success and `thenThrow(Exception())` for error tests.

Example:
```dart
blocTest<DataExportCubit, DataExportState>(
  '14.5-CUBIT-001: exportJson emits loading then success',
  build: () => DataExportCubit(mockService),
  setUp: () => when(mockService.exportJson()).thenAnswer((_) async {}),
  act: (cubit) => cubit.exportJson(),
  expect: () => [
    const DataExportState(isExporting: true),
    const DataExportState(isExporting: false),
  ],
);
```

### Files to Create (NEW)

| File | Purpose |
|------|---------|
| `pulse_coach/lib/features/settings/data/services/data_export_service.dart` | Assembles export payload, writes temp file, triggers share_plus |
| `pulse_coach/lib/features/settings/presentation/bloc/data_export_state.dart` | Cubit state |
| `pulse_coach/lib/features/settings/presentation/bloc/data_export_cubit.dart` | exportJson / exportCsv + loading/error state |
| `pulse_coach/test/bloc/data_export_cubit_test.dart` | 4 cubit unit tests |

### Files to Update (EXISTING)

| File | Change |
|------|--------|
| `pulse_coach/pubspec.yaml` | Add `share_plus: ^10.0.0` and `path_provider: ^2.1.0` |
| `pulse_coach/lib/l10n/app/app_it.arb` | Add 6 new keys |
| `pulse_coach/lib/l10n/app/app_en.arb` | Add 6 new keys |
| `pulse_coach/lib/features/settings/presentation/pages/settings_page.dart` | Add "Dati" section + ListTile + `_showExportSheet()` + `_ExportBottomSheet` private widget |

### Previous Story Learnings (14.4)

- After adding `@injectable` to any service/cubit, **always** run `flutter pub run build_runner build --delete-conflicting-outputs` — `injection.config.dart` is generated, not hand-edited.
- `@GenerateMocks([SomeClass])` on the test file requires `build_runner` to generate the `.mocks.dart` sibling file before `flutter test` can run.
- `DataExportCubit` is not `@singleton` — it is `@injectable` so it's created fresh per bottom sheet open (same pattern as `AiDecisionLogCubit`).
- The `await` keyword must be present in cubit async methods to ensure try/catch intercepts async errors (learned from 14.3 review).
- `SettingsPage` is `StatelessWidget` — `_showExportSheet` must be a top-level function or a static method, not an instance method. The `context` is passed as a parameter.
- `showModalBottomSheet` creates its own `BuildContext` subtree for the `builder` callback — you CANNOT use `context.read<DataExportCubit>()` inside the `builder` directly. Wrap with `BlocProvider(create: (_) => getIt<DataExportCubit>(), child: ...)` inside the builder.

### References

- FR52: User can export session history as CSV or JSON [epics.md line ~1946]
- Story 14.5 full ACs: [epics.md lines 1946–1967]
- `ProgressLocalDataSource.getSessionHistory()`: `pulse_coach/lib/features/progress/data/datasources/progress_local_data_source.dart:38`
- `_mondayOf()` algorithm: `pulse_coach/lib/features/progress/data/datasources/progress_local_data_source.dart:116`
- `AiDecisionLogRepository.getDecisions()`: `pulse_coach/lib/features/settings/data/repositories/ai_decision_log_repository.dart:18`
- `AiDecisionRecord` model: `pulse_coach/lib/features/settings/data/models/ai_decision_record.dart`
- `SessionHistoryEntry` entity: `pulse_coach/lib/features/progress/domain/entities/session_history_entry.dart`
- `SettingsPage` current structure: `pulse_coach/lib/features/settings/presentation/pages/settings_page.dart`
- DI injection.config.dart: `pulse_coach/lib/core/di/injection.config.dart`
- Story 14.4 cubit test pattern: `pulse_coach/test/bloc/ai_decision_log_cubit_test.dart`

### Review Findings

_Code review 2026-06-05 (Blind Hunter + Edge Case Hunter + Acceptance Auditor). 3 patch, 1 deferred, 15 dismissed as noise/spec-decided. Decision D1 (empty-data export) resolved 2026-06-05: allow empty export — MVP behavior, no guard added._

- [x] [Review][Patch] Cubit can `emit` after close if the bottom sheet is dismissed mid-export — `BlocProvider(create:)` disposes the cubit on sheet pop; the in-flight `await` then calls `emit()` and throws StateError (the catch then re-emits → uncaught). FIXED: added `if (isClosed) return;` before each emit. [pulse_coach/lib/features/settings/presentation/bloc/data_export_cubit.dart]
- [x] [Review][Patch] Temp export files are never deleted — every export writes a uniquely-named file to the cache dir and leaves it; repeated exports accumulate orphans. FIXED: temp file deleted in a `finally` (best-effort `try/catch`) after `Share.shareXFiles` returns, via `_deleteTempFile`. [pulse_coach/lib/features/settings/data/services/data_export_service.dart]
- [x] [Review][Patch] No UI test coverage for AC5 (loading spinner replaces buttons) and AC6 (localized "Errore durante l'esportazione" SnackBar + `'export_failed'`→l10n mapping). FIXED: added `14.5-WIDGET-003` (loading spinner replaces format buttons) and `14.5-WIDGET-004` (localized error SnackBar + buttons restored) with a controllable cubit. [pulse_coach/test/widget/settings_page_test.dart]
- [x] [Review][Defer] Weekly summaries grouped by UTC-Monday, not local week — a session completed late Sunday local time (UTC+1/+2) buckets into the next UTC week. Deferred, pre-existing: `_mondayOf` is byte-identical to `ProgressLocalDataSource._mondayOf` (copied per spec), so the export is internally consistent with the rest of the app; changing it is an app-wide decision, not this story's scope. [pulse_coach/lib/features/settings/data/services/data_export_service.dart:123]

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- `flutter pub get` from `pulse_coach/` completed after adding `share_plus` and `path_provider`.
- `dart run build_runner build --delete-conflicting-outputs` regenerated injectable and mockito artifacts. The installed build_runner reported that `--delete-conflicting-outputs` is ignored by this version, but generation completed successfully.
- Red phase confirmed for `test/bloc/data_export_cubit_test.dart`: initial run failed because `data_export_cubit_test.mocks.dart` had not been generated yet.
- `flutter test test/bloc/data_export_cubit_test.dart` passed after mock generation.
- `flutter test test/widget/settings_page_test.dart` passed after AC1/AC2 widget coverage was added.
- Final `flutter analyze`: no issues found.
- Final `flutter test`: 850 tests passed.

### Completion Notes List

- Added direct `share_plus` and `path_provider` dependencies and refreshed `pubspec.lock`; no Android manifest changes were needed because exports use temp/cache files and the platform share intent.
- Added localized Settings export strings for English and Italian, with generated localizations refreshed by Flutter tooling.
- Implemented `DataExportService` to reuse `ProgressLocalDataSource.getSessionHistory()` and `AiDecisionLogRepository.getDecisions()`, generate JSON with sessions, Monday-week summaries, AI decisions, and `exportedAt`, generate CSV session rows, write temp files, and invoke `Share.shareXFiles`.
- Added injectable `DataExportCubit` and `DataExportState` for export loading and error state handling.
- Added the Settings "Dati" section, "Esporta dati" tile, and export bottom sheet with JSON/CSV buttons, loading indicator, and SnackBar error message.
- Added cubit tests for JSON/CSV success and failure paths plus widget tests covering Settings entry rendering and bottom sheet format options.

### File List

- `_bmad-output/implementation-artifacts/14-5-data-export-mvp-if-time.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `pulse_coach/pubspec.yaml`
- `pulse_coach/pubspec.lock`
- `pulse_coach/lib/core/di/injection.config.dart`
- `pulse_coach/lib/features/settings/data/services/data_export_service.dart`
- `pulse_coach/lib/features/settings/presentation/bloc/data_export_cubit.dart`
- `pulse_coach/lib/features/settings/presentation/bloc/data_export_state.dart`
- `pulse_coach/lib/features/settings/presentation/pages/settings_page.dart`
- `pulse_coach/lib/l10n/app/app_en.arb`
- `pulse_coach/lib/l10n/app/app_it.arb`
- `pulse_coach/test/bloc/data_export_cubit_test.dart`
- `pulse_coach/test/bloc/data_export_cubit_test.mocks.dart`
- `pulse_coach/test/widget/settings_page_test.dart`

### Change Log

- 2026-06-05: Implemented Story 14.5 data export MVP, added localization, DI, UI, and export state tests; story marked ready for review.
