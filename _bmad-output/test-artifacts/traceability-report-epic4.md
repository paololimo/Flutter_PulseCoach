---
stepsCompleted: ['step-01-load-context', 'step-02-discover-tests', 'step-03-map-criteria', 'step-04-analyze-gaps', 'step-05-gate-decision']
lastStep: 'step-05-gate-decision'
lastSaved: '2026-04-07'
workflowType: 'bmad-testarch-trace'
scope: 'Epic 4 — Weather Layer (Stories 4.1, 4.2, 4.3)'
---

# Requirements Traceability Report — Epic 4

**Generated:** 2026-04-07
**Scope:** Epic 4 — Weather Layer (Story 4.1 Open-Meteo API, Story 4.2 Cache & TTL, Story 4.3 Location Resolution)
**Test suite baseline:** 181 tests total (28 Epic 4-specific)
**Author:** TEA Master Test Architect

---

## Gate Decision: PASS ✅

**Rationale:** P0 coverage is 100%, P1 coverage is 100% (target: 90%), and overall coverage is 91% (minimum: 80%). All in-scope P0 and P1 acceptance criteria are fully covered by unit tests. The single PARTIAL criterion (4.2-AC4) is a P2 performance assertion verified indirectly via deterministic mock probes. Three deferred sub-clauses (indoor-session routing) are formally out of Epic 4 scope per story specifications and carry explicit waiver documentation targeting Story 5.1.

---

## Coverage Summary

| Metric | Value |
|---|---|
| Total ACs (Epic 4) | 11 |
| In-scope (gate calculation) | 11 |
| Fully covered | 10 / 11 → **91%** |
| Partially covered | 1 / 11 |
| Uncovered (in-scope) | 0 / 11 |

### Priority Coverage

| Priority | Covered / Total | % | Gate Status |
|---|---|---|---|
| **P0** | **1 / 1** | **100%** | ✅ MET (required 100%) |
| **P1** | **9 / 9** | **100%** | ✅ MET (target 90%) |
| P2 | 0 / 1 | 0% | ⚠️ PARTIAL (indirect verification) |
| P3 | 0 / 0 | N/A | — |

### Gate Criteria

| Criterion | Required | Actual | Status |
|---|---|---|---|
| P0 coverage | 100% | 100% | ✅ MET |
| P1 coverage (PASS) | ≥ 90% | 100% | ✅ MET |
| P1 coverage (min) | ≥ 80% | 100% | ✅ MET |
| Overall coverage | ≥ 80% | 91% | ✅ MET |

---

## Traceability Matrix

### Story 4.1 — Open-Meteo API Integration

| AC ID | Acceptance Criterion | Priority | Tests | Coverage | Notes |
|---|---|---|---|---|---|
| **4.1-AC1** | Temperatura, precipitazione e AQI recuperati e persistiti in `weather_cache` con `cachedAt` (FR33, FR34, NFR8) | P1 | 4.1-UNIT-001, 4.1-UNIT-003, 4.1-UNIT-004 | **FULL** | DS: fetch success + AQI alto (120). Repo: cacheWeather chiamato una volta su success path. |
| **4.1-AC2** | Solo coordinate city-level (1 decimale) inviate all'API — no GPS preciso (FR35, NFR8) | P1 | 4.3-UNIT-004, 4.3-UNIT-005, 4.3-UNIT-007, 4.1-UNIT-004 | **FULL** | LocationService arrotonda prima di restituire (48.856→48.9, negativo corretto). LocationAccuracy.low verificato. Repo passa i valori arrotondati al remote. |
| **4.1-AC3** | AQI ≥ 100 → `isAqiHigh=true`; sessioni constrained a indoor per Story 5.1 | P1 | 4.1-UNIT-007, 4.1-UNIT-011 | **FULL** | Proprietà entity testata: AQI=110→true, AQI=99→false (boundary). Indoor routing è Story 5.1 scope — waiver formale. |
| **4.1-AC4** | API error → `Left(ServerFailure)` — nessuna eccezione propagata (ARCH8, ARCH9) | P1 | 4.1-UNIT-002, 4.1-UNIT-006, 4.1-UNIT-010 | **FULL** | DS: DioException + non-DioException → ServerException. Repo: ServerException → Left(ServerFailure). |

### Story 4.2 — Weather Cache & TTL Management

| AC ID | Acceptance Criterion | Priority | Tests | Coverage | Notes |
|---|---|---|---|---|---|
| **4.2-AC1** | Cache valida (< 1h) → dati restituiti senza network call (NFR5, NFR14) | P1 | 4.2-UNIT-001 | **FULL** | Fresh cache (30min) → Right(cached), verifyNever su fetchWeatherAndAqi. |
| **4.2-AC2** | Cache stale (> 1h) + API raggiungibile → dati freschi, cache aggiornata | P1 | 4.2-UNIT-002, 4.2-UNIT-003, 4.2-UNIT-006, 4.2-UNIT-008 | **FULL** | Stale 2h, no-cache, boundary esatto 1h → tutti triggherano fetch. replaceCache → ≤1 riga. |
| **4.2-AC3** | Cache stale + API irraggiungibile → dati stale restituiti con `cachedAt` originale (FR36) | P1 | 4.2-UNIT-004, 4.2-UNIT-005 | **FULL** | Stale + timeout → Right(staleContext). No cache + timeout → Left(ServerFailure). La regola "indoor se AQI > 2h" è formalmente Story 5.1 scope (doc in story review); `cachedAt` intatto per Story 5.1. |
| **4.2-AC4** | Letture offline successive < 500ms (NFR5) | P2 | 4.2-UNIT-001 | **PARTIAL** | Verificato indirettamente: nessuna chiamata network quando cache valida (verifyNever). Nessun benchmark temporale diretto. Performance garantita architetturalmente (cache Drift sync-like). |

### Story 4.3 — City-Level Location Resolution

| AC ID | Acceptance Criterion | Priority | Tests | Coverage | Notes |
|---|---|---|---|---|---|
| **4.3-AC1** | Coordinate arrotondate a 1 decimale (~11km) prima di qualsiasi uso o storage (FR35, NFR8) | P0 | 4.3-UNIT-004, 4.3-UNIT-005, 4.3-UNIT-007 | **FULL** | Nord (48.856→48.9, 2.352→2.4), Sud/Ovest (-33.869→-33.9, -70.673→-70.7), LocationAccuracy.low verificato via capture. |
| **4.3-AC2** | Permission denied → `Left(LocationFailure)` (FR36) | P1 | 4.3-UNIT-001, 4.3-UNIT-002, 4.3-UNIT-003, 4.3-UNIT-006, 4.3-UNIT-008, 4.1-UNIT-005 | **FULL** | Servizio disabilitato, denied after re-request, permanentemente denied, GPS exception, first-launch happy path. LocationFailure propagata attraverso il repo chain. Indoor default è Story 5.1 scope. |
| **4.3-AC3** | Solo coordinate arrotondate memorizzate — GPS raw mai persistito | P1 | 4.3-UNIT-004, 4.3-UNIT-005, 4.1-UNIT-004 | **FULL** | Garanzia architetturale documentata: LocationService arrotonda → Repo passa il risultato arrotondato a cacheWeather (nessun accesso diretto a raw GPS nel path di storage). Dev notes: "AC3 Already Satisfied". Layer verificati indipendentemente; flow end-to-end garantito dalla struttura del codice. |

---

## Test Inventory (28 test Epic 4)

### Story 4.1 — WeatherRemoteDataSource (4 test)

| Test ID | Descrizione | Livello | File |
|---|---|---|---|
| 4.1-UNIT-001 | `fetchWeatherAndAqi()` success → WeatherModel(22.5°C, 40%) + AqiModel(45) | Unit | `test/data/datasources/weather_remote_data_source_test.dart` |
| 4.1-UNIT-002 | `fetchWeatherAndAqi()` DioException → ServerException | Unit | `test/data/datasources/weather_remote_data_source_test.dart` |
| 4.1-UNIT-003 | `fetchWeatherAndAqi()` AQI=120 (sopra soglia) → parsato correttamente | Unit | `test/data/datasources/weather_remote_data_source_test.dart` |
| 4.1-UNIT-010 | `fetchWeatherAndAqi()` non-DioException → ServerException via `catch(e)` | Unit | `test/data/datasources/weather_remote_data_source_test.dart` |

### Story 4.1/4.2 — WeatherRepositoryImpl (12 test)

| Test ID | Descrizione | Livello | File |
|---|---|---|---|
| 4.1-UNIT-004 | Location ok + API ok → Right(WeatherContext), cacheWeather chiamato | Unit | `test/data/repositories/weather_repository_impl_test.dart` |
| 4.1-UNIT-005 | Location denied → Left(LocationFailure), remote NOT called | Unit | `test/data/repositories/weather_repository_impl_test.dart` |
| 4.1-UNIT-006 | ServerException → Left(ServerFailure) | Unit | `test/data/repositories/weather_repository_impl_test.dart` |
| 4.1-UNIT-006b | Cache write CacheException → non-fatal, Right(fresh data) restituito | Unit | `test/data/repositories/weather_repository_impl_test.dart` |
| 4.1-UNIT-007 | AQI=110 → WeatherContext.isAqiHigh == true | Unit | `test/data/repositories/weather_repository_impl_test.dart` |
| 4.2-UNIT-001 | Fresh cache (30min) → Right(cached), fetchWeatherAndAqi NOT called | Unit | `test/data/repositories/weather_repository_impl_test.dart` |
| 4.2-UNIT-002 | Stale (2h) + API ok → fresh data, cacheWeather called once | Unit | `test/data/repositories/weather_repository_impl_test.dart` |
| 4.2-UNIT-003 | No cache + API ok → fresh data, cacheWeather called once | Unit | `test/data/repositories/weather_repository_impl_test.dart` |
| 4.2-UNIT-004 | Stale + API unreachable → Right(staleContext), cachedAt originale preservato | Unit | `test/data/repositories/weather_repository_impl_test.dart` |
| 4.2-UNIT-005 | No cache + API unreachable → Left(ServerFailure) | Unit | `test/data/repositories/weather_repository_impl_test.dart` |
| 4.2-UNIT-007 | getCachedWeather CacheException → non-fatal, fallthrough a network | Unit | `test/data/repositories/weather_repository_impl_test.dart` |
| 4.2-UNIT-008 | Cache esattamente 1h old → stale, network fetch triggered (boundary TTL) | Unit | `test/data/repositories/weather_repository_impl_test.dart` |

### Story 4.1 — GetWeatherContext use case (3 test)

| Test ID | Descrizione | Livello | File |
|---|---|---|---|
| 4.1-UNIT-008 | Repo Right → UC Right (pass-through verificato) | Unit | `test/domain/usecases/get_weather_context_test.dart` |
| 4.1-UNIT-009 | Repo Left(ServerFailure) → UC Left (pass-through verificato) | Unit | `test/domain/usecases/get_weather_context_test.dart` |
| 4.1-UNIT-011 | WeatherContext.isAqiHigh = false a AQI=99 (boundary sotto soglia ≥100) | Unit | `test/domain/usecases/get_weather_context_test.dart` |

### Story 4.2 — WeatherCacheDao (1 test)

| Test ID | Descrizione | Livello | File |
|---|---|---|---|
| 4.2-UNIT-006 | `replaceCache` con riga esistente → esattamente 1 riga in tabella | Unit | `test/core/database/daos/weather_cache_dao_test.dart` |

### Story 4.3 — LocationService (8 test)

| Test ID | Descrizione | Livello | File |
|---|---|---|---|
| 4.3-UNIT-001 | Location services disabled → Left(LocationFailure) | Unit | `test/core/utils/location_service_test.dart` |
| 4.3-UNIT-002 | Permission denied dopo re-request → Left(LocationFailure) | Unit | `test/core/utils/location_service_test.dart` |
| 4.3-UNIT-003 | Permission permanently denied → Left(LocationFailure), requestPermission NOT called | Unit | `test/core/utils/location_service_test.dart` |
| 4.3-UNIT-004 | Success → coordinate arrotondate (48.856→48.9, 2.352→2.4) — AC1 | Unit | `test/core/utils/location_service_test.dart` |
| 4.3-UNIT-005 | Coordinate negative arrotondate correttamente (-33.869→-33.9) | Unit | `test/core/utils/location_service_test.dart` |
| 4.3-UNIT-006 | Eccezione generica da getCurrentPosition → Left(LocationFailure) | Unit | `test/core/utils/location_service_test.dart` |
| 4.3-UNIT-007 | Verifica LocationAccuracy.low via capture — city-level sufficiente (NFR8) | Unit | `test/core/utils/location_service_test.dart` |
| 4.3-UNIT-008 | denied → requestPermission → whileInUse → Right (first-launch happy path) | Unit | `test/core/utils/location_service_test.dart` |

---

## Gap Analysis

### Parzialmente Coperto

| AC ID | Gap | Raccomandazione | Priorità |
|---|---|---|---|
| 4.2-AC4 | Performance < 500ms: verificata indirettamente via verifyNever(network call). Nessun benchmark temporale esplicito. | Architetturalmente garantita da Drift (lettura locale sincrona). Aggiungere benchmark se introdotto latency regression in Epic 5+. | P2/Low |

### Deferred per Story Spec (Non in Gate Calc)

| AC / Clausola | Gap | Rationale | Epic Target |
|---|---|---|---|
| 4.1-AC3 (routing indoor) | Sessioni constrained a indoor quando AQI ≥ 100 | Story 4.1 spec: "Story 5.1 classifies it". Entity property `isAqiHigh` testata qui; routing è StateVector responsibility. | Epic 5 — Story 5.1 |
| 4.2-AC3 (2h AQI indoor) | Sessions default to indoor se AQI stale > 2h | Story 4.2 review: "Deferred to Story 5.1. Indoor-forcing on stale AQI > 2h belongs to StateVector builder". `cachedAt` intatto per input a 5.1. | Epic 5 — Story 5.1 |
| 4.3-AC2 (indoor default) | System defaults to indoor on LocationFailure | Comportamento routing non implementato in Epic 4. LocationFailure propagata correttamente attraverso il chain (testato). | Epic 5 — Story 5.1 |

### Deferred per Design (Review Findings)

| Finding | Test | Descrizione |
|---|---|---|
| Story 4.2: Cache per wrong location | — | No lat/lon comparison tra cache e coordinate correnti. Pre-existing trade-off: single-entry cache per spec. Deferred. |
| Story 4.2: DateTime.now() not injectable | — | `_isCacheValid` usa `DateTime.now()` direttamente. Deferred, pre-existing architectural pattern. |
| Story 4.2: Drift DateTime UTC round-trip | — | isUtc flag inconsistency tra fresh fetch e DB read. Deferred, pre-existing. |
| Story 4.3: `unableToDetermine` enum | — | Enum case non gestito, cade in getCurrentPosition. Deferred, pre-existing. |
| Story 4.3: Dead `LocationServiceDisabledException` catch | — | Catch quasi-unreachable (coperto da service check sopra). Deferred, pre-existing. |

---

## Coverage Heuristics

| Heuristic | Conteggio | Note |
|---|---|---|
| Endpoint senza test | 0 | Open-Meteo weather + AQI endpoints entrambi coperti in 4.1-UNIT-001/002/003 |
| Auth/authz negative-path mancanti | 0 | Permission-denied coperto (4.3-UNIT-001/002/003; LocationFailure propagata in 4.1-UNIT-005) |
| Criteri solo happy-path | 0 | Tutti i P0/P1 hanno failure paths coperti (ServerException, CacheException, LocationFailure, DioException) |

---

## Recommendations

| Priorità | Azione | Requisiti |
|---|---|---|
| HIGH | Implementare indoor-routing per LocationFailure/AQI-stale in Epic 5 Story 5.1 — prerequisito per plan generation | 4.1-AC3, 4.2-AC3, 4.3-AC2 |
| MEDIUM | Considerare benchmark test per 4.2-AC4 (< 500ms) se aggiunta latency in Epic 5+ | 4.2-AC4 |
| LOW | Review boundary value per `_isCacheValid` con clock injection in Epic 5+ (test 4.2-UNIT-008 usa subtract(1h) che resta leggermente instabile su macchine lente) | 4.2-AC2 |

---

## Test Count Timeline

| Milestone | Count |
|---|---|
| Pre-Epic 4 baseline | 153 |
| After Story 4.1 (+14) | 167 |
| After Story 4.2 (+3 story + 4 review patches) | 170 |
| After Story 4.3 (+8 incl. review patch) | 178 |
| After TEA automate (+3 gap closures) | **181** |

---

## Next Actions

1. ✅ Epic 4 traceability matrix completata — pronti per Epic 5
2. Prima di Epic 5: Story 5.1 deve referenziare esplicitamente 4.1-AC3 + 4.2-AC3 + 4.3-AC2 come AC da soddisfare (indoor-routing su LocationFailure e AQI stale)
3. Eseguire `cd pulse_coach && flutter test` prima di iniziare Epic 5 per verificare baseline a 181 test
4. Eseguire `/bmad-testarch-automate` dopo ogni nuova epic

---

## Gate Decision Summary

```
✅ GATE DECISION: PASS

📊 Coverage Analysis:
- P0 Coverage: 100% (Required: 100%) → ✅ MET
- P1 Coverage: 100% (PASS target: 90%, minimum: 80%) → ✅ MET
- Overall Coverage: 91% (Minimum: 80%) → ✅ MET

✅ Decision Rationale:
P0 coverage is 100%, P1 coverage is 100% (target: 90%), and overall
coverage is 91% (minimum: 80%). All in-scope P0/P1 ACs are fully covered.
Single PARTIAL item (4.2-AC4) is P2 with indirect performance verification.
Three indoor-routing sub-clauses carry formal Story 5.1 waivers per story spec.

⚠️ Concerns: 1
- 4.2-AC4 (P2): Performance < 500ms verified indirectly via no-network-call
  assertion. No explicit temporal benchmark.

📝 Top Recommendations:
1. [HIGH] Implement indoor-routing (LocationFailure/AQI-stale) in Epic 5 Story 5.1
2. [MEDIUM] Add perf benchmark for 4.2-AC4 if latency regression observed
3. [LOW] Clock injection for _isCacheValid in future refactor

📂 Full Report: _bmad-output/test-artifacts/traceability-report.md

✅ GATE: PASS — Release approved for Epic 4, coverage meets standards
```
