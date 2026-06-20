---
stepsCompleted: ['step-01-load-context', 'step-02-discover-tests', 'step-03-map-criteria', 'step-04-analyze-gaps', 'step-05-gate-decision']
lastStep: 'step-05-gate-decision'
lastSaved: '2026-04-04'
workflowType: 'bmad-testarch-trace'
scope: 'Epic 3 — Sensor Layer (Stories 3.1, 3.2, 3.3)'
---

# Requirements Traceability Report — Epic 3

**Generated:** 2026-04-04
**Scope:** Epic 3 — Sensor Layer (Story 3.1 Health API, Story 3.2 Accelerometer, Story 3.3 RPE-Only Fallback)
**Test suite baseline:** 153 tests total (31 Epic 3-specific)
**Author:** TEA Master Test Architect

---

## Gate Decision: PASS ✅

**Rationale:** P0 coverage is 100%, P1 coverage is 100% (target: 90%), and overall in-scope coverage is 82% (minimum: 80%). All in-scope P0 and P1 acceptance criteria are fully covered by unit tests. The two deferred criteria (3.3-AC2, 3.3-AC3) are formally out of Epic 3 scope per story specifications and carry waiver documentation.

---

## Coverage Summary

| Metric | Value |
|---|---|
| Total ACs (Epic 3) | 14 |
| In-scope (gate calculation) | 11 |
| Deferred (formal waivers) | 2 |
| Waived (spike-verified) | 1 |
| Fully covered | 9 / 11 → **82%** |
| Partially covered | 1 / 11 |
| Uncovered (in-scope) | 0 / 11 |

### Priority Coverage

| Priority | Covered / Total | % | Gate Status |
|---|---|---|---|
| **P0** | **3 / 3** | **100%** | ✅ MET (required 100%) |
| **P1** | **6 / 6** | **100%** | ✅ MET (target 90%) |
| P2 | 0 / 1 | 0% | ⚠️ PARTIAL only |
| P3 | 0 / 0 | N/A | — |

### Gate Criteria

| Criterion | Required | Actual | Status |
|---|---|---|---|
| P0 coverage | 100% | 100% | ✅ MET |
| P1 coverage (PASS) | ≥ 90% | 100% | ✅ MET |
| P1 coverage (min) | ≥ 80% | 100% | ✅ MET |
| Overall coverage | ≥ 80% | 82% | ✅ MET |

---

## Traceability Matrix

### Story 3.1 — Health API Integration (HR & Steps)

| AC ID | Acceptance Criterion | Priority | Tests | Coverage | Notes |
|---|---|---|---|---|---|
| **3.1-AC1** | Permission prompt includes "Used to personalize your sessions. Stays on your device." | P3 | — | **WAIVED** | Verified in Epic 3 spike (iOS Info.plist, Android manifest). Not unit-testable. |
| **3.1-AC2** | Permissions granted → `HealthData` con `restingHr` (nullable) + `stepCount` (nullable) | P1 | 3.1-UNIT-001, 003, 005, 011 | **FULL** | Copre: dati presenti, lista vuota (Android), più punti sommati |
| **3.1-AC3** | Fetch ok → `saveHealthData` persiste in `behavioral_state` con `recordedAt` | P1 | 3.1-UNIT-007, 009 | **FULL** | Verifica companion corretto + orchestrazione in GetHealthData |
| **3.1-AC4** | `GetHealthData` injectable e testabile; contratto disponibile per Story 5.1 | P1 | 3.1-UNIT-009, 010 | **FULL** | Registrazione DI verificata; contratto Either<Failure, HealthData> ✓ |
| **3.1-AC5** | Dati esclusivamente on-device, nessuna trasmissione di rete | P2 | 3.1-UNIT-007 (indiretto) | **PARTIAL** | Il test verifica la chiamata a `behavioralStateDao.insertState()` (DB locale drift). Nessun test assertisce esplicitamente l'assenza di network calls. Architetturalmente garantito. |
| **3.1-AC6** | Permissions denied → `Left(SensorFailure('Health permissions denied'))` | P0 | 3.1-UNIT-002, 006, 010 | **FULL** | DataSource → Repository → UseCase chain completa |
| **3.1-AC7** | `HealthDataSource` cattura eccezioni generiche e rilancia come `SensorException` | P1 | 3.1-UNIT-004 | **FULL** | Wrapping eccezione piattaforma verificato |

### Story 3.2 — Accelerometer Activity Detection

| AC ID | Acceptance Criterion | Priority | Tests | Coverage | Notes |
|---|---|---|---|---|---|
| **3.2-AC1** | Accelerometro disponibile → classifica `sedentary` / `moderate` / `active` (FR43) | P1 | 3.2-UNIT-001, 002, 003, 005, 008 | **FULL** | Tutte e 3 le classi verificate; repository e use case coperti |
| **3.2-AC2** | `GetActivityLevel` injectable e testabile; contratto disponibile per Story 5.1 | P1 | 3.2-UNIT-008, 009 | **FULL** | Registrazione DI verificata; contratto Either<Failure, ActivityLevel> ✓ |
| **3.2-AC3** | Accelerometro non disponibile → `Left(SensorFailure('Accelerometer unavailable'))` | P0 | 3.2-UNIT-004, 006, 007, 009, 010, 011, 012 | **FULL** | Copre: stream error, SensorException, unexpected exception, empty stream, pochi campioni, timeout |

### Story 3.3 — RPE-Only Fallback Mode

| AC ID | Acceptance Criterion | Priority | Tests | Coverage | Notes |
|---|---|---|---|---|---|
| **3.3-AC1** | Tutti i permessi negati → campi null → `isRpeOnly == true` (FR44, NFR21) | P0 | 3.3-UNIT-004, 006 | **FULL** | Both-fail + eccezione non catturata → SensorContext all-null |
| **3.3-AC2** | RPE-only → bandit seleziona sessioni da RPE/profilo/contesto | P0 | — | **DEFERRED** | **Epic 5 scope** (Story 5.1 DailyPlanBloc). Story 3.3 spec: "Do NOT implement DailyPlanBloc". Contratto stabilito: `SensorContext.isRpeOnly` disponibile. |
| **3.3-AC3** | RPE-only → StateIndicator mostra spiegazione dati disponibili | P1 | — | **DEFERRED** | **Epic 7 scope** (UI stories). Story 3.3 spec: "AC3 is Epic 7 responsibility". |
| **3.3-EXTRA** | GetSensorContext lancia GetHealthData + GetActivityLevel in concorrenza (Future.wait) | P1 | 3.3-UNIT-001..005 | **FULL** | Verifica tutti i casi di composizione: entrambi ok, health fail, activity fail, entrambi fail, dati parziali |

---

## Test Inventory (31 test Epic 3)

### Story 3.1 — HealthDataSource (5 test)

| Test ID | Descrizione | Livello | File |
|---|---|---|---|
| 3.1-UNIT-001 | `fetchHealthData()` ritorna `HealthData` con HR e steps quando permissions granted | Unit | `test/data/datasources/health_data_source_test.dart` |
| 3.1-UNIT-002 | `fetchHealthData()` lancia `SensorException('Health permissions denied')` quando `requestAuthorization` = false | Unit | `test/data/datasources/health_data_source_test.dart` |
| 3.1-UNIT-003 | `fetchHealthData()` ritorna `HealthData(null, null)` quando entrambe le liste sono vuote | Unit | `test/data/datasources/health_data_source_test.dart` |
| 3.1-UNIT-004 | `fetchHealthData()` wrappa eccezioni sconosciute come `SensorException` | Unit | `test/data/datasources/health_data_source_test.dart` |
| 3.1-UNIT-011 | `fetchHealthData()` somma correttamente più punti step (2000 + 3500 = 5500) | Unit | `test/data/datasources/health_data_source_test.dart` |

### Story 3.1 — HealthRepositoryImpl (4 test)

| Test ID | Descrizione | Livello | File |
|---|---|---|---|
| 3.1-UNIT-005 | `fetchHealthData()` ritorna `Right(HealthData)` quando datasource ha successo | Unit | `test/data/repositories/health_repository_impl_test.dart` |
| 3.1-UNIT-006 | `fetchHealthData()` ritorna `Left(SensorFailure)` quando datasource lancia `SensorException` | Unit | `test/data/repositories/health_repository_impl_test.dart` |
| 3.1-UNIT-007 | `saveHealthData()` chiama `behavioralStateDao.insertState()` con companion corretto | Unit | `test/data/repositories/health_repository_impl_test.dart` |
| 3.1-UNIT-008 | `saveHealthData()` ritorna `Left(CacheFailure)` quando DB lancia eccezione | Unit | `test/data/repositories/health_repository_impl_test.dart` |

### Story 3.1 — GetHealthData use case (3 test)

| Test ID | Descrizione | Livello | File |
|---|---|---|---|
| 3.1-UNIT-009 | `call()` esegue fetch poi save quando fetch ha successo; ritorna `Right(HealthData)` | Unit | `test/domain/usecases/get_health_data_test.dart` |
| 3.1-UNIT-010 | `call()` ritorna `Left(SensorFailure)` senza chiamare save quando fetch fallisce | Unit | `test/domain/usecases/get_health_data_test.dart` |
| 3.1-UNIT-012 | `call()` ritorna `Right(data)` anche quando `saveHealthData` fallisce (comportamento deferrito) | Unit | `test/domain/usecases/get_health_data_test.dart` |

### Story 3.2 — AccelerometerDataSource (8 test)

| Test ID | Descrizione | Livello | File |
|---|---|---|---|
| 3.2-UNIT-001 | Ritorna `sedentary` quando std dev < 0.3 (30 sample uniformi) | Unit | `test/data/datasources/accelerometer_data_source_test.dart` |
| 3.2-UNIT-002 | Ritorna `moderate` quando std dev tra 0.3 e 1.5 | Unit | `test/data/datasources/accelerometer_data_source_test.dart` |
| 3.2-UNIT-003 | Ritorna `active` quando std dev >= 1.5 | Unit | `test/data/datasources/accelerometer_data_source_test.dart` |
| 3.2-UNIT-004 | Lancia `SensorException` quando stream lancia errore | Unit | `test/data/datasources/accelerometer_data_source_test.dart` |
| 3.2-UNIT-010 | Lancia `SensorException` su stream vuoto | Unit | `test/data/datasources/accelerometer_data_source_test.dart` |
| 3.2-UNIT-011 | Lancia `SensorException` quando meno di `_minSampleCount` campioni | Unit | `test/data/datasources/accelerometer_data_source_test.dart` |
| 3.2-UNIT-012 | Lancia `SensorException` su timeout stream (5s) | Unit | `test/data/datasources/accelerometer_data_source_test.dart` |
| 3.2-UNIT-013 | Salta eventi NaN magnitude; classifica con i campioni validi rimanenti | Unit | `test/data/datasources/accelerometer_data_source_test.dart` |

### Story 3.2 — SensorRepositoryImpl (3 test)

| Test ID | Descrizione | Livello | File |
|---|---|---|---|
| 3.2-UNIT-005 | `fetchActivityLevel()` ritorna `Right(ActivityLevel.active)` quando datasource ha successo | Unit | `test/data/repositories/sensor_repository_impl_test.dart` |
| 3.2-UNIT-006 | `fetchActivityLevel()` ritorna `Left(SensorFailure)` quando datasource lancia `SensorException` | Unit | `test/data/repositories/sensor_repository_impl_test.dart` |
| 3.2-UNIT-007 | `fetchActivityLevel()` ritorna `Left(SensorFailure)` su eccezione non attesa | Unit | `test/data/repositories/sensor_repository_impl_test.dart` |

### Story 3.2 — GetActivityLevel use case (2 test)

| Test ID | Descrizione | Livello | File |
|---|---|---|---|
| 3.2-UNIT-008 | `call()` delega a `SensorRepository.fetchActivityLevel()` e ritorna il risultato | Unit | `test/domain/usecases/get_activity_level_test.dart` |
| 3.2-UNIT-009 | `call()` ritorna `Left(SensorFailure)` quando repository ritorna failure | Unit | `test/domain/usecases/get_activity_level_test.dart` |

### Story 3.3 — GetSensorContext use case (6 test)

| Test ID | Descrizione | Livello | File |
|---|---|---|---|
| 3.3-UNIT-001 | Entrambe le sorgenti ok → tutti i campi popolati; `isRpeOnly == false` | Unit | `test/domain/usecases/get_sensor_context_test.dart` |
| 3.3-UNIT-002 | Health fail, activity ok → HR/steps null, activityLevel valorizzato; `isRpeOnly == false` | Unit | `test/domain/usecases/get_sensor_context_test.dart` |
| 3.3-UNIT-003 | Health ok, activity fail → HR/steps valorizzati, activityLevel null; `isRpeOnly == false` | Unit | `test/domain/usecases/get_sensor_context_test.dart` |
| 3.3-UNIT-004 | Entrambe fail → tutti null; `isRpeOnly == true`, `hasSensorData == false` | Unit | `test/domain/usecases/get_sensor_context_test.dart` |
| 3.3-UNIT-005 | Health ok con dati parziali (solo steps) → `SensorContext(null, 6100, null)`; `isRpeOnly == false` | Unit | `test/domain/usecases/get_sensor_context_test.dart` |
| 3.3-UNIT-006 | Dependency lancia eccezione non catturata → SensorContext all-null (review patch F1) | Unit | `test/domain/usecases/get_sensor_context_test.dart` |

---

## Gap Analysis

### Deferred (Fuori Scope Epic 3)

| AC ID | Gap | Rationale | Epic Target |
|---|---|---|---|
| 3.3-AC2 | Bandit funziona in RPE-only mode | Story 3.3 spec: "Do NOT implement DailyPlanBloc". Contratto definito: `SensorContext.isRpeOnly` disponibile per Epic 5 | Epic 5 — Story 5.1 |
| 3.3-AC3 | StateIndicator explanation in RPE-only mode | Story 3.3 spec: "AC3 is Epic 7 responsibility" | Epic 7 — UI stories |

### Parzialmente Coperto

| AC ID | Gap | Raccomandazione | Priorità |
|---|---|---|---|
| 3.1-AC5 | On-device only: nessun test assertisce esplicitamente l'assenza di network calls | Architetturalmente garantito da drift (SQLite locale). Considerare aggiunta di test negativo in integration test Epic 6+ che verifichi l'assenza di chiamate HTTP durante `saveHealthData`. | P2/Low |

### Deferred per Design (Review Findings)

| Finding | Test | Descrizione |
|---|---|---|
| Story 3.1 F1 | 3.1-UNIT-012 | `saveHealthData` failure silently dropped — comportamento deferrito documentato dal test; Epic 5 definirà la strategia di error handling persistenza |
| Story 3.2 F3 (boundary) | — | Test ai valori esatti soglia (stdDev == 0.3, == 1.5) non implementati per instabilità floating-point. Deferred P3. |

---

## Coverage Heuristics

| Heuristic | Conteggio | Note |
|---|---|---|
| Endpoint senza test | 0 | Architettura offline-first; nessun HTTP endpoint coinvolto in Epic 3 |
| Auth/authz negative-path mancanti | 0 | Permission-denied coperto (3.1-UNIT-002, 006, 010; 3.2-UNIT-004, 006) |
| Criteri solo happy-path | 0 | Tutti i P0/P1 hanno failure path coperti |

---

## Recommendations

| Priorità | Azione | Requisiti |
|---|---|---|
| HIGH | Implementare 3.3-AC2 (bandit RPE-only) in Epic 5 Story 5.1 — prerequisito per plan generation | 3.3-AC2 |
| HIGH | Implementare 3.3-AC3 (StateIndicator RPE-only) in Epic 7 UI stories | 3.3-AC3 |
| MEDIUM | Aggiungere test negativo per 3.1-AC5 (on-device only) a integration test level in Epic 6+ | 3.1-AC5 |
| LOW | Considerare boundary value tests per AccelerometerDataSource (stdDev == 0.3, == 1.5) in P3 backlog | 3.2 edge cases |

---

## Next Actions

1. ✅ Epic 3 traceability matrix completata — pronti per Epic 4
2. Prima di Epic 5: verificare che Story 5.1 referenzi esplicitamente 3.3-AC2 come AC da soddisfare
3. Prima di Epic 7: verificare che le UI stories referenzino 3.3-AC3
4. Eseguire `/bmad-testarch-automate` dopo ogni nuova epic per mantenere la copertura

---

## Gate Decision Summary

```
✅ GATE DECISION: PASS

📊 Coverage Analysis:
- P0 Coverage: 100% (Required: 100%) → ✅ MET
- P1 Coverage: 100% (PASS target: 90%, minimum: 80%) → ✅ MET
- Overall Coverage: 82% (Minimum: 80%) → ✅ MET

✅ Decision Rationale:
P0 coverage is 100%, P1 coverage is 100% (target: 90%), and overall
in-scope coverage is 82% (minimum: 80%). The two deferred criteria
(3.3-AC2, 3.3-AC3) carry formal waivers per story specifications.

⚠️ Concerns: 1
- 3.1-AC5 (P2): On-device constraint partially verified (architecture-enforced).

📝 Top Recommendations:
1. [HIGH] Implement 3.3-AC2 (bandit RPE-only) in Epic 5 Story 5.1
2. [HIGH] Implement 3.3-AC3 (StateIndicator RPE-only) in Epic 7 UI stories
3. [MEDIUM] Add integration test for on-device constraint (3.1-AC5)

📂 Full Report: _bmad-output/test-artifacts/traceability-report.md

✅ GATE: PASS — Release approved for Epic 3, coverage meets standards
```
