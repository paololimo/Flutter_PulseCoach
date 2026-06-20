# Story 14.3: Device & Sync Settings Screen

Status: done

## Story

As a user,
I want to manage my device integrations and sync status from a settings screen,
So that I can understand and control what the app connects to.

## Acceptance Criteria

**AC1 — Screen shows four info sections (FR50):**
Given the user navigates to Settings and taps "Dispositivo e Sync"
When the Device & Sync settings screen renders
Then it shows all four sections:
- Health API permission status (granted/denied/unknown) (FR50)
- WearOS connection status (connected/disconnected) (FR50)
- Sync queue status with pending items count (FR50)
- Cache info: last weather update date + last exercise cache date (FR50)

**AC2 — Re-request Health permission (FR50):**
Given the user taps "Richiedi permesso" on the Health API row
When the system processes the request
Then the OS permission dialog appears (or is skipped if already granted on Android) and the
status row updates to reflect the new permission state after the user responds

**AC3 — Sync Now button visibility and action (FR50):**
Given the sync queue has pending items
When the device settings screen renders with network connectivity present
Then a "Sincronizza ora" button is visible and tapping it triggers `SyncManager.processQueue()`

Given the sync queue has no pending items OR network is unavailable
When the screen renders
Then the "Sincronizza ora" button is absent

## Tasks / Subtasks

- [x] Task 1: Add ARB keys (AC1, AC2, AC3)
  - [x] 1.1 Add 16 new keys to `pulse_coach/lib/l10n/app/app_it.arb`
  - [x] 1.2 Add the same 16 keys to `pulse_coach/lib/l10n/app/app_en.arb`
  - [x] 1.3 Run `flutter pub get` to regenerate `app_localizations*.dart`

- [x] Task 2: Create `DeviceSettingsState` (AC1, AC2, AC3)
  - [x] 2.1 Create `pulse_coach/lib/features/settings/presentation/bloc/device_settings_state.dart`
  - [x] 2.2 Fields: `isLoading`, `healthPermissionGranted` (bool?), `isWearConnected` (bool?),
            `pendingSyncCount`, `weatherCachedAt` (DateTime?), `exerciseCachedAt` (DateTime?),
            `isOnline`

- [x] Task 3: Create `DeviceSettingsCubit` (AC1, AC2, AC3)
  - [x] 3.1 Create `pulse_coach/lib/features/settings/presentation/bloc/device_settings_cubit.dart`
  - [x] 3.2 Annotate `@injectable`; constructor accepts `HealthDataSource`, `SyncQueueDao`,
            `WeatherCacheDao`, `ExerciseCacheDao`, `SyncManager`, `Connectivity`
  - [x] 3.3 `load()` method: parallel fetch of all status fields → emit loaded state
  - [x] 3.4 `requestHealthPermission()`: call `_health.requestAuthorization(...)` then re-emit status
  - [x] 3.5 `syncNow()`: call `SyncManager.processQueue()` then `load()` to refresh count
  - [x] 3.6 Run `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate
            `injection.config.dart`

- [x] Task 4: Create `DeviceSettingsPage` (AC1, AC2, AC3)
  - [x] 4.1 Create `pulse_coach/lib/features/settings/presentation/pages/device_settings_page.dart`
  - [x] 4.2 `BlocBuilder<DeviceSettingsCubit, DeviceSettingsState>` — shows shimmer while loading
  - [x] 4.3 Health section: status text + "Richiedi permesso" `OutlinedButton` when not granted
  - [x] 4.4 WearOS section: status chip (connected/disconnected)
  - [x] 4.5 Sync section: pending count text + "Sincronizza ora" button when pending > 0 AND online
  - [x] 4.6 Cache section: two rows (weather + exercise) with formatted date or "Non disponibile"

- [x] Task 5: Wire route and SettingsPage link
  - [x] 5.1 Add `static const String deviceSettings = '/device-settings'` to `AppRouter`
  - [x] 5.2 Add `GoRoute` for `deviceSettings` with `BlocProvider(create: (_) =>
            getIt<DeviceSettingsCubit>()..load(), child: const DeviceSettingsPage())`
  - [x] 5.3 Add `ListTile` to `SettingsPage`: "Dispositivo e Sync" → `context.push(AppRouter.deviceSettings)`
            and a `RefreshIndicator` or `onResume` in `DeviceSettingsPage` to reload on return

- [x] Task 6: Add tests
  - [x] 6.1 Create `pulse_coach/test/bloc/device_settings_cubit_test.dart`
      - [x] `14.3-CUBIT-001`: `load()` emits loaded state with healthPermission from `hasPermissions`
      - [x] `14.3-CUBIT-002`: `load()` emits isWearConnected from `WatchConnectivity.isReachable`
      - [x] `14.3-CUBIT-003`: `load()` emits pendingSyncCount = count of entries in queue
      - [x] `14.3-CUBIT-004`: `load()` emits `weatherCachedAt` from `WeatherCacheDao.getLatestCache()`
      - [x] `14.3-CUBIT-005`: `requestHealthPermission()` calls `requestAuthorization` then reloads
      - [x] `14.3-CUBIT-006`: `syncNow()` calls `SyncManager.processQueue()` then reloads
  - [x] 6.2 Create `pulse_coach/test/widget/device_settings_page_test.dart`
      - [x] `14.3-WIDGET-001`: page shows health permission status label
      - [x] `14.3-WIDGET-002`: "Richiedi permesso" button visible when `healthPermissionGranted == false`
      - [x] `14.3-WIDGET-003`: "Richiedi permesso" button absent when `healthPermissionGranted == true`
      - [x] `14.3-WIDGET-004`: "Sincronizza ora" button visible when `pendingSyncCount > 0 && isOnline`
      - [x] `14.3-WIDGET-005`: "Sincronizza ora" button absent when `pendingSyncCount == 0`

- [x] Task 7: Verify
  - [x] 7.1 Run `flutter test` from `pulse_coach/`. Target: ≥ 827 + 11 new = ≥ 838 total. All existing tests green.
  - [x] 7.2 Run `flutter analyze` from `pulse_coach/`. Must be 0 issues.

### Review Findings

_Code review 2026-06-05 — 0 decision-needed, 4 patch, 0 deferred, 3 dismissed as noise. All 4 patches applied; flutter analyze clean, flutter test 839/839._

- [x] [Review][Patch] Duplicate "WearOS" label — `_WearRow` `ListTile.title` repeated the `_SectionHeader` text. FIXED: row now shows the connection status (Connesso/Non connesso) as title with a watch icon as leading; chip removed [pulse_coach/lib/features/settings/presentation/pages/device_settings_page.dart]
- [x] [Review][Patch] Plural i18n wrong at count==1 — `deviceSettingsSyncPending` was a plain `{count}` placeholder. FIXED: converted to ICU plural (`one`/`other`) in both ARB files [pulse_coach/lib/l10n/app/app_it.arb / app_en.arb]
- [x] [Review][Patch] Missing `await` defeated the local try/catch in `_fetchHealthPermission` and `_fetchWearStatus`. FIXED: added `await` so the catch intercepts async errors [pulse_coach/lib/features/settings/presentation/bloc/device_settings_cubit.dart]
- [x] [Review][Patch] Unused `copyWith` dead code. FIXED: removed from `DeviceSettingsState` [pulse_coach/lib/features/settings/presentation/bloc/device_settings_state.dart]

## Dev Notes

### What Is Already In Place (Do NOT Reinvent)

- **`SettingsPage`** at `pulse_coach/lib/features/settings/presentation/pages/settings_page.dart` — **UPDATE target**. Already shows the theme toggle section. Add a new "Dispositivo e Sync" `ListTile` below the theme section.
- **`/settings` route** is already registered in `app_router.dart` (line 101). The new `/device-settings` route is a sibling — add it after the `settings` route entry.
- **`HealthDataSource`** at `pulse_coach/lib/features/session/data/datasources/health_data_source.dart` — already injectable (`@injectable`) and registered in DI. Its `_health` field is the `Health` singleton. `Health.hasPermissions(types, permissions: perms)` (returns `bool?`: `null` = never asked, `true` = granted, `false` = denied) and `Health.requestAuthorization(types, permissions: perms)` (returns `bool`) are the two APIs needed.
- **`SyncQueueDao`** at `pulse_coach/lib/core/database/daos/sync_queue_dao.dart` — already registered in DI via `HealthModule`. Use `getPendingEntries()` to get pending count.
- **`WeatherCacheDao`** — registered in DI. Use `getLatestCache()` → `WeatherCacheData?` with `.cachedAt` field.
- **`ExerciseCacheDao`** — registered in DI. Use `getAll()` → find the entry with max `.cachedAt` (all exercises share the same 24h TTL window, so any entry's `cachedAt` works as a proxy).
- **`SyncManager`** (`@singleton`) at `pulse_coach/lib/core/sync/sync_manager.dart` — already registered in DI. Use `processQueue()` for the "Sync Now" action.
- **`Connectivity`** (`@singleton`) from `connectivity_plus` — already registered in DI (line 143 of `injection.config.dart`). Use `checkConnectivity()` → `List<ConnectivityResult>` to determine `isOnline`.
- **`WatchConnectivity`** from `watch_connectivity` — NOT registered in DI; it is instantiated directly as `WatchConnectivity()` in `WearBridgeService`. In `DeviceSettingsCubit`, instantiate it directly too: `WatchConnectivity().isReachable`. Wrap in try/catch — it may throw on Android when no companion app is installed.
- **`ThemeCubit`** is `@lazySingleton` and provided globally in `app.dart` — it does NOT need to be re-provided for `DeviceSettingsPage`. The new `DeviceSettingsCubit` is `@injectable` (transient factory) — provided at route level.
- **ARB pipeline** is fully wired: source at `lib/l10n/app/app_it.arb` + `app_en.arb`; generated files are `.gitignore`d.
- **`injection.config.dart` is GENERATED** — do NOT edit it manually. After adding `@injectable` to `DeviceSettingsCubit`, run `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate.

### DeviceSettingsState — Full Definition

```dart
// pulse_coach/lib/features/settings/presentation/bloc/device_settings_state.dart
import 'package:equatable/equatable.dart';

class DeviceSettingsState extends Equatable {
  const DeviceSettingsState({
    this.isLoading = true,
    this.healthPermissionGranted,
    this.isWearConnected,
    this.pendingSyncCount = 0,
    this.weatherCachedAt,
    this.exerciseCachedAt,
    this.isOnline = false,
  });

  final bool isLoading;
  final bool? healthPermissionGranted; // null = never asked
  final bool? isWearConnected;         // null = check failed (no companion)
  final int pendingSyncCount;
  final DateTime? weatherCachedAt;
  final DateTime? exerciseCachedAt;
  final bool isOnline;

  DeviceSettingsState copyWith({
    bool? isLoading,
    bool? healthPermissionGranted,
    bool? isWearConnected,
    int? pendingSyncCount,
    DateTime? weatherCachedAt,
    DateTime? exerciseCachedAt,
    bool? isOnline,
  }) => DeviceSettingsState(
    isLoading: isLoading ?? this.isLoading,
    healthPermissionGranted:
        healthPermissionGranted ?? this.healthPermissionGranted,
    isWearConnected: isWearConnected ?? this.isWearConnected,
    pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
    weatherCachedAt: weatherCachedAt ?? this.weatherCachedAt,
    exerciseCachedAt: exerciseCachedAt ?? this.exerciseCachedAt,
    isOnline: isOnline ?? this.isOnline,
  );

  @override
  List<Object?> get props => [
    isLoading,
    healthPermissionGranted,
    isWearConnected,
    pendingSyncCount,
    weatherCachedAt,
    exerciseCachedAt,
    isOnline,
  ];
}
```

> **Note on `copyWith` and nullable fields:** The `copyWith` pattern above cannot clear a previously-set nullable field back to `null` (the `??` short-circuits). This is acceptable for this cubit because `load()` always emits a fresh state from scratch, never uses `copyWith`. If that constraint changes in a future story, adopt the `Value<T>` sentinel pattern.

### DeviceSettingsCubit — Shape

```dart
// pulse_coach/lib/features/settings/presentation/bloc/device_settings_cubit.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/database/daos/exercise_cache_dao.dart';
import 'package:pulse_coach/core/database/daos/sync_queue_dao.dart';
import 'package:pulse_coach/core/database/daos/weather_cache_dao.dart';
import 'package:pulse_coach/core/sync/sync_manager.dart';
import 'package:pulse_coach/features/session/data/datasources/health_data_source.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/device_settings_state.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

@injectable
class DeviceSettingsCubit extends Cubit<DeviceSettingsState> {
  DeviceSettingsCubit(
    this._healthDataSource,
    this._syncQueueDao,
    this._weatherCacheDao,
    this._exerciseCacheDao,
    this._syncManager,
    this._connectivity,
  ) : super(const DeviceSettingsState());

  final HealthDataSource _healthDataSource;
  final SyncQueueDao _syncQueueDao;
  final WeatherCacheDao _weatherCacheDao;
  final ExerciseCacheDao _exerciseCacheDao;
  final SyncManager _syncManager;
  final Connectivity _connectivity;

  Future<void> load() async {
    // Run all fetches in parallel; degrade gracefully on errors.
    final results = await Future.wait([
      _fetchHealthPermission(),
      _fetchWearStatus(),
      _fetchSyncCount(),
      _fetchWeatherCacheDate(),
      _fetchExerciseCacheDate(),
      _fetchOnlineStatus(),
    ]);

    emit(DeviceSettingsState(
      isLoading: false,
      healthPermissionGranted: results[0] as bool?,
      isWearConnected: results[1] as bool?,
      pendingSyncCount: results[2] as int,
      weatherCachedAt: results[3] as DateTime?,
      exerciseCachedAt: results[4] as DateTime?,
      isOnline: results[5] as bool,
    ));
  }

  Future<bool?> _fetchHealthPermission() async {
    try {
      return await _healthDataSource.checkPermissions();
    } catch (_) {
      return null;
    }
  }

  Future<bool?> _fetchWearStatus() async {
    try {
      return await WatchConnectivity().isReachable;
    } catch (_) {
      return null; // No companion app installed or platform error
    }
  }

  Future<int> _fetchSyncCount() async {
    try {
      return (await _syncQueueDao.getPendingEntries()).length;
    } catch (_) {
      return 0;
    }
  }

  Future<DateTime?> _fetchWeatherCacheDate() async {
    try {
      return (await _weatherCacheDao.getLatestCache())?.cachedAt;
    } catch (_) {
      return null;
    }
  }

  Future<DateTime?> _fetchExerciseCacheDate() async {
    try {
      final all = await _exerciseCacheDao.getAll();
      if (all.isEmpty) return null;
      return all.map((e) => e.cachedAt).reduce((a, b) => a.isAfter(b) ? a : b);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _fetchOnlineStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  Future<void> requestHealthPermission() async {
    try {
      await _healthDataSource.requestPermissions();
    } catch (_) {
      // Silent: re-load will reflect the actual post-dialog state.
    }
    await load();
  }

  Future<void> syncNow() async {
    await _syncManager.processQueue();
    await load();
  }
}
```

### HealthDataSource — Two New Methods to Add

The cubit needs `checkPermissions()` and `requestPermissions()` on `HealthDataSource`. Add both to the existing file:

```dart
// In health_data_source.dart — add these two methods:

/// Returns the current Health permission state without fetching data.
/// Returns null if the permission state is unknown (never asked on this device).
Future<bool?> checkPermissions() async {
  try {
    await _health.configure();
    return await _health.hasPermissions(
      _readTypes,
      permissions: _readPermissions,
    );
  } catch (_) {
    return null;
  }
}

/// Triggers the OS Health permission dialog.
/// Returns true if permissions were granted.
Future<bool> requestPermissions() async {
  try {
    await _health.configure();
    return await _health.requestAuthorization(
      _readTypes,
      permissions: _readPermissions,
    );
  } catch (_) {
    return false;
  }
}
```

`_readTypes` and `_readPermissions` are the existing `static const` fields — no duplication needed.

### DeviceSettingsPage — Shape

```dart
// pulse_coach/lib/features/settings/presentation/pages/device_settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/device_settings_cubit.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/device_settings_state.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class DeviceSettingsPage extends StatefulWidget {
  const DeviceSettingsPage({super.key});

  @override
  State<DeviceSettingsPage> createState() => _DeviceSettingsPageState();
}

class _DeviceSettingsPageState extends State<DeviceSettingsPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    // Reload when returning to the app after the Health permission dialog.
    if (lifecycle == AppLifecycleState.resumed) {
      context.read<DeviceSettingsCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.deviceSettingsPageTitle)),
      body: BlocBuilder<DeviceSettingsCubit, DeviceSettingsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionHeader(l10n.deviceSettingsHealthSection),
              _HealthRow(state: state, l10n: l10n),
              const SizedBox(height: 24),
              _SectionHeader(l10n.deviceSettingsWearSection),
              _WearRow(state: state, l10n: l10n),
              const SizedBox(height: 24),
              _SectionHeader(l10n.deviceSettingsSyncSection),
              _SyncRow(state: state, l10n: l10n),
              const SizedBox(height: 24),
              _SectionHeader(l10n.deviceSettingsCacheSection),
              _CacheRow(
                label: l10n.deviceSettingsCacheWeather,
                date: state.weatherCachedAt,
                l10n: l10n,
              ),
              _CacheRow(
                label: l10n.deviceSettingsCacheExercise,
                date: state.exerciseCachedAt,
                l10n: l10n,
              ),
            ],
          );
        },
      ),
    );
  }
}
```

Private helper widgets (`_SectionHeader`, `_HealthRow`, `_WearRow`, `_SyncRow`, `_CacheRow`) should all be in the same file — no separate widget files needed for this story.

`_HealthRow` logic:
- If `healthPermissionGranted == true` → show label `deviceSettingsHealthGranted` (green check icon)
- If `healthPermissionGranted == false` → show label `deviceSettingsHealthDenied` (red × icon) + `OutlinedButton(l10n.deviceSettingsHealthReRequest, ...)`
- If `healthPermissionGranted == null` → show label `deviceSettingsHealthUnknown`

`_SyncRow` logic:
- Always show count text: if `pendingSyncCount == 0` → `deviceSettingsSyncNone`; else format as `"$pendingSyncCount elementi in sospeso"`
- Show `ElevatedButton(l10n.deviceSettingsSyncNow, ...)` only when `state.pendingSyncCount > 0 && state.isOnline`

`_CacheRow` logic:
- If date is null → show `l10n.deviceSettingsCacheNone`
- Else format as `DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal())`

> **Important:** `intl` is already a transitive dependency (used by `flutter_localizations`). Import `package:intl/intl.dart` for `DateFormat`. Do NOT add it to `pubspec.yaml` — it is already available.

### SettingsPage — Change Required

Add a new "Device & Sync" section below the existing theme section:

```dart
// In settings_page.dart, after the SizedBox(height: 8) + SegmentedButton block:
const SizedBox(height: 24),
Text(
  l10n.deviceSettingsNavSection,
  style: Theme.of(context).textTheme.titleSmall,
),
const SizedBox(height: 8),
ListTile(
  contentPadding: EdgeInsets.zero,
  title: Text(l10n.deviceSettingsNavTile),
  trailing: const Icon(Icons.chevron_right),
  onTap: () => context.push(AppRouter.deviceSettings),
),
```

> **Note:** `context.push` (not `context.go`) because the user should be able to pop back to Settings.

### app_router.dart — Route to Add

```dart
// Add this constant alongside the others:
static const String deviceSettings = '/device-settings';

// Add this route after the existing `settings` GoRoute entry:
GoRoute(
  path: deviceSettings,
  builder: (context, state) => BlocProvider(
    create: (_) => getIt<DeviceSettingsCubit>()..load(),
    child: const DeviceSettingsPage(),
  ),
),
```

Import `DeviceSettingsCubit` and `DeviceSettingsPage` at the top of `app_router.dart`.

### ARB Keys — What to Add

Add 16 keys to **both** `app_it.arb` and `app_en.arb`, after the existing `settingsThemeSystem` entry.

**Italian (`app_it.arb`):**
```json
"deviceSettingsNavSection": "Dispositivo",
"deviceSettingsNavTile": "Dispositivo e Sync",
"deviceSettingsPageTitle": "Dispositivo e Sincronizzazione",
"deviceSettingsHealthSection": "API Salute",
"deviceSettingsHealthGranted": "Permesso concesso",
"deviceSettingsHealthDenied": "Permesso negato",
"deviceSettingsHealthUnknown": "Stato sconosciuto",
"deviceSettingsHealthReRequest": "Richiedi permesso",
"deviceSettingsWearSection": "WearOS",
"deviceSettingsWearConnected": "Connesso",
"deviceSettingsWearDisconnected": "Non connesso",
"deviceSettingsSyncSection": "Sincronizzazione",
"deviceSettingsSyncNone": "Nessun elemento in sospeso",
"deviceSettingsSyncNow": "Sincronizza ora",
"deviceSettingsCacheSection": "Cache",
"deviceSettingsCacheWeather": "Ultimo aggiornamento meteo",
"deviceSettingsCacheExercise": "Ultimo aggiornamento esercizi",
"deviceSettingsCacheNone": "Non disponibile"
```

Wait — that's 18 keys. Keeping all of them for completeness is the right call.

**English (`app_en.arb`):**
```json
"deviceSettingsNavSection": "Device",
"deviceSettingsNavTile": "Device & Sync",
"deviceSettingsPageTitle": "Device & Sync Settings",
"deviceSettingsHealthSection": "Health API",
"deviceSettingsHealthGranted": "Permission granted",
"deviceSettingsHealthDenied": "Permission denied",
"deviceSettingsHealthUnknown": "Status unknown",
"deviceSettingsHealthReRequest": "Request permission",
"deviceSettingsWearSection": "WearOS",
"deviceSettingsWearConnected": "Connected",
"deviceSettingsWearDisconnected": "Not connected",
"deviceSettingsSyncSection": "Sync Queue",
"deviceSettingsSyncNone": "No items pending",
"deviceSettingsSyncNow": "Sync now",
"deviceSettingsCacheSection": "Cache",
"deviceSettingsCacheWeather": "Last weather update",
"deviceSettingsCacheExercise": "Last exercise update",
"deviceSettingsCacheNone": "Not available"
```

### Widget Tests — Pattern

```dart
// pulse_coach/test/widget/device_settings_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/device_settings_cubit.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/device_settings_state.dart';
import 'package:pulse_coach/features/settings/presentation/pages/device_settings_page.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class MockDeviceSettingsCubit extends MockCubit<DeviceSettingsState>
    implements DeviceSettingsCubit {}

Widget _buildPage(DeviceSettingsCubit cubit) => MaterialApp(
      locale: const Locale('it'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider.value(value: cubit, child: const DeviceSettingsPage()),
    );
```

Use `whenListen` / `when(() => cubit.state).thenReturn(...)` from `bloc_test`/`mocktail` to seed specific states for each test. Confirm `bloc_test` and `mocktail` are already in `dev_dependencies` before referencing them.

### Cubit Tests — Pattern

```dart
// pulse_coach/test/bloc/device_settings_cubit_test.dart
// Mock all 6 dependencies with Mockito/Mocktail.
// For each test call `cubit.load()` and verify the emitted state.
// Use `verify(() => mockSyncManager.processQueue()).called(1)` for syncNow.
```

Check `dev_dependencies` in `pubspec.yaml` first — the project already uses `mocktail` or `mockito`; match the existing pattern.

### Architecture Constraints (Do Not Violate)

- `injection.config.dart` is GENERATED — never edit manually. Always run `build_runner` after adding `@injectable` to a new class.
- `DeviceSettingsCubit` must be `@injectable` (transient factory), NOT `@lazySingleton`, because health permission state changes between navigations and we want fresh data each time.
- `DeviceSettingsPage` must NOT access the Drift database directly — all data flows through the cubit.
- `WatchConnectivity` must be instantiated locally inside `_fetchWearStatus()` — it is not in the DI container and must not be registered there (it's a session-scoped service in `WearBridgeService`). Always wrap in try/catch.
- `flutter analyze` must remain at **0 issues** after implementation.
- All text via `AppLocalizations` — no hardcoded strings in widget files.
- Date formatting via `DateFormat` from `intl` (already a transitive dep) — do NOT add to `pubspec.yaml`.

### Test Infra Check — Required Before Writing Tests

Before writing tests, run:
```bash
grep -E "mocktail|mockito|bloc_test" pulse_coach/pubspec.yaml
```
Confirm the mock library already in `dev_dependencies`. Previous stories (e.g. 14.1 `settings_page_test.dart`) use `SharedPreferences.setMockInitialValues` but not external mock libraries — **check if `mocktail` is present before using it**. If not, use `fakeable` constructors or manual fakes for the cubit in widget tests.

> **For cubit unit tests specifically:** all 6 dependencies are interfaces/concrete classes that accept constructor injection. Prefer `mocktail` if available. If it is not in `dev_dependencies`, create lightweight fakes by subclassing.

### Current Test Baseline

As of Story 14.2 done (2026-06-05): `flutter test` passes with **827/827** tests.

New tests this story:
- `device_settings_cubit_test.dart`: 6 cubit unit tests
- `device_settings_page_test.dart`: 5 widget tests
- Total new: **11** tests

Target after story: ≥ **838** tests.

### File Changes Summary

**MODIFY:**
- `pulse_coach/lib/features/session/data/datasources/health_data_source.dart` — add `checkPermissions()` and `requestPermissions()` methods
- `pulse_coach/lib/features/settings/presentation/pages/settings_page.dart` — add "Device & Sync" section with `ListTile`
- `pulse_coach/lib/core/routing/app_router.dart` — add `deviceSettings` constant + `GoRoute`
- `pulse_coach/lib/l10n/app/app_it.arb` — 18 new keys
- `pulse_coach/lib/l10n/app/app_en.arb` — 18 new keys

**CREATE:**
- `pulse_coach/lib/features/settings/presentation/bloc/device_settings_state.dart`
- `pulse_coach/lib/features/settings/presentation/bloc/device_settings_cubit.dart`
- `pulse_coach/lib/features/settings/presentation/pages/device_settings_page.dart`
- `pulse_coach/test/bloc/device_settings_cubit_test.dart` — 6 unit tests
- `pulse_coach/test/widget/device_settings_page_test.dart` — 5 widget tests

**REGENERATED (do not manually edit):**
- `pulse_coach/lib/core/di/injection.config.dart` — via `flutter pub run build_runner build --delete-conflicting-outputs`
- `pulse_coach/lib/l10n/app_localizations*.dart` — via `flutter pub get`

### References

- Story ACs: `_bmad-output/planning-artifacts/epics.md` §Epic 14, Story 14.3
- FR50: `_bmad-output/planning-artifacts/prd.md`
- `HealthDataSource` (UPDATE): `pulse_coach/lib/features/session/data/datasources/health_data_source.dart`
- `Health.hasPermissions` API: `~/.pub-cache/hosted/pub.dev/health-13.3.1/lib/src/health_plugin.dart` line 112
- `SyncQueueDao`: `pulse_coach/lib/core/database/daos/sync_queue_dao.dart`
- `WeatherCacheDao`: `pulse_coach/lib/core/database/daos/weather_cache_dao.dart`
- `ExerciseCacheDao`: `pulse_coach/lib/core/database/daos/exercise_cache_dao.dart`
- `SyncManager`: `pulse_coach/lib/core/sync/sync_manager.dart`
- `WearBridgeService` (pattern for `WatchConnectivity` usage): `pulse_coach/lib/features/session/presentation/utils/wear_bridge_service.dart`
- `SettingsPage` (UPDATE): `pulse_coach/lib/features/settings/presentation/pages/settings_page.dart`
- `AppRouter` (UPDATE): `pulse_coach/lib/core/routing/app_router.dart`
- Previous story (14.2): `_bmad-output/implementation-artifacts/14-2-privacy-information-screen.md`
- Settings page tests (widget test pattern): `pulse_coach/test/widget/settings_page_test.dart`
- DI pattern for injectable cubits: `pulse_coach/lib/features/today/presentation/cubit/today_session_cubit.dart` (`@injectable`)
- Route-level BlocProvider pattern: `pulse_coach/lib/core/routing/app_router.dart` lines 51-58

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- `flutter pub get` — passed; regenerated localization outputs from ARB.
- `flutter pub run build_runner build --delete-conflicting-outputs` — passed; regenerated DI and Mockito mocks.
- `dart format ...` — passed.
- `flutter test test/bloc/device_settings_cubit_test.dart test/widget/device_settings_page_test.dart` — passed, 11/11.
- `flutter analyze` — passed, 0 issues.
- `flutter test` — passed, 839/839.

### Completion Notes List

- Implemented the Device & Sync settings flow with route-level `DeviceSettingsCubit` provisioning and SettingsPage navigation via `context.push`.
- Added Health permission status/re-request support through `HealthDataSource.checkPermissions()` and `requestPermissions()`.
- DeviceSettingsCubit now fetches Health, WearOS, sync queue, cache timestamps, and connectivity concurrently with graceful fallback behavior.
- DeviceSettingsPage renders the four required sections, shimmer loading, pull-to-refresh, app-resume reload, conditional Health permission and Sync Now actions, and localized cache date display.
- Added 11 new tests covering cubit status/action behavior and widget visibility rules.
- Added one extra localized `deviceSettingsSyncPending` placeholder key beyond the story's corrected 18-key list to avoid hardcoded pending-count copy in the widget.

### File List

- `_bmad-output/implementation-artifacts/14-3-device-and-sync-settings-screen.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `pulse_coach/lib/core/di/injection.config.dart`
- `pulse_coach/lib/core/routing/app_router.dart`
- `pulse_coach/lib/features/session/data/datasources/health_data_source.dart`
- `pulse_coach/lib/features/settings/presentation/bloc/device_settings_cubit.dart`
- `pulse_coach/lib/features/settings/presentation/bloc/device_settings_state.dart`
- `pulse_coach/lib/features/settings/presentation/pages/device_settings_page.dart`
- `pulse_coach/lib/features/settings/presentation/pages/settings_page.dart`
- `pulse_coach/lib/l10n/app/app_en.arb`
- `pulse_coach/lib/l10n/app/app_it.arb`
- `pulse_coach/test/bloc/device_settings_cubit_test.dart`
- `pulse_coach/test/bloc/device_settings_cubit_test.mocks.dart`
- `pulse_coach/test/data/repositories/health_repository_impl_test.mocks.dart`
- `pulse_coach/test/widget/device_settings_page_test.dart`
- `pulse_coach/test/widget/device_settings_page_test.mocks.dart`

### Change Log

- 2026-06-05: Implemented Device & Sync settings screen, route, settings link, Health permission helpers, localization keys, DI registration, and test coverage for Story 14.3.
