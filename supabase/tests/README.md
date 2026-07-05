# Database tests (pgTAP)

These files close the Epic 21 traceability gaps that are pure server-side
SQL/PL-pgSQL logic (points cap clamp, friends-only RLS, the Story 21.4
drop-out sweep) — previously verified only by code-read trace because this
repo had no live-DB test harness.

## Running

```bash
supabase start   # requires Docker; spins up local Postgres + pgTAP
supabase test db
```

Each file runs inside a transaction that's rolled back at the end (`BEGIN`/
`ROLLBACK`), so they don't leave fixture data behind and can run against the
same local database repeatedly.

## Coverage

| File | Closes |
|---|---|
| `leaderboard_scoring.test.sql` | 21.1-AC2 (daily cap clamp), 21.2-AC1 (friends-only RLS negative path) |
| `shared_session_scoring.test.sql` | 21.3-AC2 (shared-session bonus cap clamp) |
| `shared_session_sweep.test.sql` | 21.4-AC1, AC2, AC3 (drop-out sweep: active-only scoring, grace-window/already-scored/no-op untouched sessions, mutual exclusivity with the client-triggered path) |

## Known limitation

These files were authored without executing them — the authoring
environment had neither Docker nor `psql` available, so `supabase start` /
`supabase test db` could not be run to verify they pass. Run them locally or
in CI before treating these gaps as closed; if they fail, the fixtures or
assertions (not necessarily the underlying SQL) are the first thing to
check.
