# Sync Engine

Documentation of the offline sync engine: pushing locally-written Drift records up to Supabase. Written to be a complete standing reference — every decision, every piece of architecture, every known gap — so future phases and next-version work don't have to reconstruct context from chat history.

**Status as of this writing: all 7 build phases complete and tested, plus three post-launch fixes found during manual device testing — the Batches pull, its generalization to all 8 synced entities (§4.6), and logout hard-blocking (D2, revised). `flutter analyze` clean, 44/44 tests passing.**

---

## 1. Scope

### What this engine does
Pushes local Drift (SQLite) writes made on mobile up to Supabase, once connectivity allows, for the 8 device-writable entity tables: Batches, Expenses, MortalityEntries, FeedEntries, WeightSamples, VaccinationEntries, HarvestEntries, Sales.

### What this engine explicitly does not do (non-goals for this version)
- **No general pull/merge.** It does not pull other devices' writes back down into local Drift for entry-type data (Expenses, MortalityEntries, FeedEntries, WeightSamples, VaccinationEntries, HarvestEntries, Sales). Mobile UI reads only from local Drift for these.
  **One deliberate, narrow exception: Batches.** A read-only cache-refresh pull for `Batches` was added after initial testing surfaced a real functional gap — see §4.6. This is not a reopening of D3's broader non-goal (no conflict resolution for concurrent edits); it's a one-directional overwrite-the-cache refresh, identical in shape to the pre-existing Account refresh, scoped to a table Staff never locally edits.
- **No background sync.** Everything is foreground-triggered (app must be open). No WorkManager, no BackgroundFetch, no headless execution.
- **No conflict resolution between two online, concurrently-editing devices** beyond the one specific case the system defends against: bird-count totals exceeding a batch's starting count (handled server-side, see §4, D1).
- **No retry/backoff policy.** A failed push just sits in the queue until the next trigger (connectivity regained, next local write, next login) tries again. No exponential backoff, no retry cap. **This is a known, deliberate gap — see §8.**
- **No UI for reviewing/resolving rejected rows.** A row rejected by the server-side bird-count trigger sits flagged in the queue forever with no in-app way to inspect or clear it except direct DB access. **Known gap — see §8.**
- **Web is untouched.** Web reads/writes Supabase directly, has no local Drift database, and none of this applies to it.

---

## 2. Data model this engine operates on

### Entities & local write behavior

| Table | Local writes | Notes |
|---|---|---|
| `Businesses` | none | Server-authoritative; mobile never writes |
| `Accounts` | none (mobile) | `upsertAll` only — caches what Supabase says; excluded from sync push |
| `Batches` | insert, **update** | `assignStaff()` and `close()` mutate existing rows |
| `Expenses` | insert only | |
| `MortalityEntries` | insert only | Feeds the bird-count composite rule; subject to server-side rejection |
| `FeedEntries` | insert only | |
| `WeightSamples` | insert only | |
| `VaccinationEntries` | insert only | |
| `HarvestEntries` | insert only | Feeds the bird-count composite rule; subject to server-side rejection |
| `Sales` | insert only | References `HarvestEntries`, not `Batches` directly |

### Foreign-key / push order
```
Businesses
  └─ Accounts        (server-authoritative, not pushed)
       └─ Batches    (assignedStaffId, closedBy → Accounts)
            ├─ Expenses
            ├─ MortalityEntries
            ├─ FeedEntries
            ├─ WeightSamples
            ├─ VaccinationEntries
            └─ HarvestEntries
                 └─ Sales
```
`SyncService` walks tables in this fixed order (`batches`, `expenses`, `mortality_entries`, `feed_entries`, `weight_samples`, `vaccination_entries`, `harvest_entries`, `sales`), not by queue timestamp — a Sale queued after its Harvest must never be pushed first even if retried out of original order, since Supabase will reject a Sale whose `harvest_id` doesn't exist yet.

### Identity
All entity IDs are client-generated UUIDs, created at write time and reused verbatim when the row reaches Supabase. **No ID remapping anywhere in this engine.**

### Roles (for context — RLS depends on this)
Four roles, strict separation: `super_admin` (owns all businesses), `admin` (manages one business, read-only on farm data), `manager` (owns a business, records expenses/sales, closes batches), `staff` (records mortality/harvest/weight/vaccination/feed only for batches assigned to them). Mobile writes are almost all Staff-originated field data plus Manager-originated batch/financial actions; Admin and Super Admin never write farm data locally.

---

## 3. Design decisions

### D1 — Bird-count integrity is re-validated server-side
**Decision:** On push, Supabase rejects (does not silently accept or auto-correct) any insert that would push `mortality + harvested` past a batch's `starting_bird_count`. The rejection is a real backend trigger, already implemented in the production schema: `check_batch_bird_count()`, firing `before insert` on both `mortality_entry` and `harvest_entry`.

**Why:** The local domain-layer check (`bird_count_rule.dart`) only sees one device's state — including its own queued-but-unsynced rows, since those already live in local Drift regardless of sync status. What it *cannot* see is another device's unsynced writes against the same batch. Two devices, both offline, both logging against the same batch, can each pass their local check and still blow the limit once both sync. Bird counts are not reversible data; a silent over-count is worse than a flagged row.

**Backend implementation** (already in production Supabase schema):
```sql
create or replace function public.check_batch_bird_count()
returns trigger language plpgsql as $$
declare
  v_starting integer; v_total_mortality integer; v_total_harvested integer;
begin
  select starting_bird_count into v_starting from public.batch where batch_id = new.batch_id;
  select coalesce(sum(count), 0) into v_total_mortality from public.mortality_entry where batch_id = new.batch_id;
  select coalesce(sum(bird_count), 0) into v_total_harvested from public.harvest_entry where batch_id = new.batch_id;
  if tg_table_name = 'mortality_entry' then v_total_mortality := v_total_mortality + new.count;
  elsif tg_table_name = 'harvest_entry' then v_total_harvested := v_total_harvested + new.bird_count;
  end if;
  if v_total_mortality + v_total_harvested > v_starting then
    raise exception 'mortality plus harvested (%) cannot exceed this batch''s starting bird count (%)',
      v_total_mortality + v_total_harvested, v_starting;
  end if;
  return new;
end; $$;
```
The local check and this trigger are deliberately layered: local check = instant feedback for the common single-device case; trigger = backstop for the genuinely cross-device case the local check structurally cannot see.

**Flutter-side handling (D5, see below):** a rejection from this trigger is distinguished from an ordinary network/RLS failure and is never auto-retried.

### D2 — Logout attempts a blocking sync, then hard-blocks on anything still pending/failed
**Decision (revised after manual testing):** Before any logout dialog appears, the engine awaits a bounded `SyncService.drain()` call (15s timeout), so the counts reflect post-drain reality rather than a stale pre-sync number. `drainAndCountUnsyncedRows()` returns both `total` (all unsynced, rejected included) and `blocking` (pending/failed only, rejected excluded):
- **`blocking > 0`** → logout is **fully and permanently blocked** — not a warning the user can click past. An "Cannot log out yet" dialog states N record(s) haven't reached the server and that logout isn't possible until they do; single OK button, no logout path at all.
- **`blocking == 0` but `total > 0`** (only rejected rows remain) → the original informational warning dialog, with logout still allowed to proceed.
- **`total == 0`** → silent, as always.

**Why the revision from the original "warn and allow anyway" design:** the original version was built, tested, and then found insufficient against the actual threat it was meant to address — a warning dialog with a "log out anyway" button does nothing to stop someone else picking up an unlocked phone and logging out to erase evidence of unsynced work; a warning a person can dismiss isn't a safeguard against that. Hard-blocking is the only thing that actually prevents data loss from that scenario.

**Why rejected rows are the one exception, not swept into the same hard block:** a rejected row (D5 — the bird-count trigger) can *never* resolve itself no matter how long the device waits or how many times it retries — nothing retries it, by design. Hard-blocking logout on something structurally incapable of resolving would permanently trap the device, unable to log out at all until someone manually intervenes in the database (and there's no in-app UI to do that — §8.2). That's a worse failure mode than the data-loss risk the block exists to prevent, so rejected rows fall through to the original warn-and-allow path instead.

**Implementation note:** `countUnsyncedRows()` was renamed `drainAndCountUnsyncedRows()` back when it first gained its side effect (a bounded network drain) — the old name was no longer accurate for a method that isn't a pure, free local read. It now also returns a `{total, blocking}` pair (`UnsyncedCounts` record typedef) rather than a single `int`, since the hard-block logic and the informational warning need different numbers.

### D3 — Push-only, no pull/merge, in this version
**Decision:** Confirmed, see §1 non-goals. The engine pushes local writes to Supabase and does not pull other devices' writes back into local Drift for any entity covered here.

**Why:** Confirmed by the codebase at design time — mobile UI reads only from local Drift, and there's no existing pull pattern besides Account's `upsertAll`. Adding pull/merge means designing conflict resolution for concurrent edits, a materially larger problem deliberately out of scope for this version.

### D4 — Sync is foreground-triggered, not a background task
**Decision:** Sync runs on: regaining connectivity, a debounced interval after each local write, and once after login. No WorkManager/BackgroundFetch/headless execution.

**Why:** Nothing for background execution existed in the project at design time (not in `pubspec.yaml`, no platform setup) — adding it would be a separate, larger decision than this engine needed to make unilaterally.

### D5 — Bird-count rejections stop auto-retrying, don't blend into generic failures
**Decision:** A row rejected by the D1 trigger is flagged (`SyncQueue.rejected = true`) rather than treated as a transient failure. Rejected rows:
- stay in the queue (never deleted, so the data itself isn't lost),
- are excluded from `pendingRows()` so `SyncService.drain()` never re-attempts them automatically,
- still count in `pendingCount()` / the logout warning, since they are still genuinely unsynced,
- have no in-app review/resolution UI yet (**known gap, §8**).

**Why:** A rejected row will never succeed on retry until a human resolves the actual data conflict it represents (e.g. two offline devices both logged harvest against the same batch, now over-total). Treating it like a generic network failure means hammering Supabase with an identical doomed request on every connectivity blip and every subsequent local write — noise, not resilience, and it would also mask genuinely transient failures in the same bucket.

---

## 4. Architecture

### 4.1 Sync queue (`SyncQueue` Drift table, schema v3)

| Column | Type | Notes |
|---|---|---|
| `id` | int, PK | Auto-increment |
| `entityTable` | text | e.g. `'batches'`, `'harvest_entries'` — **named `entityTable`, not `tableName`** (see §7 gotcha below: `tableName` collides with Drift's own reserved `Table.tableName` getter and breaks codegen) |
| `recordId` | text | The entity's client-generated UUID |
| `operation` | text, CHECK `IN ('insert','update')` | Only Batches produces `'update'` rows today |
| `createdAt` | datetime | Default: now. Queue ordering within a table, not the source row's own timestamp |
| `attempts` | int, default 0 | Incremented on `markFailed()` only (not on `markRejected()`) |
| `lastError` | text, nullable | Error from the most recent failed/rejected attempt |
| `rejected` | bool, default false | Added in Phase 6 (schema bump to v3). `true` means: stop auto-retrying, keep for manual review |

Enqueued in the same transaction as the local write/update it describes. Every `record()`-style write across all 8 entity repositories enqueues `operation: 'insert'`; `Batches.assignStaff()` and `Batches.close()` enqueue `operation: 'update'`.

**Why a queue table instead of a per-row dirty flag:** a flag only tells you *that* something needs syncing, not *in what order*, and has nowhere to record retry count/last error without adding those columns to every entity table individually. A dedicated queue centralizes that, and matches the mechanism `countUnsyncedRows()`'s original code comment already anticipated before this engine existed.

### 4.2 Push strategy: `upsert()`, not strict insert/update
Every push — regardless of the queue row's `operation` value — writes to Supabase via `upsert()`, keyed on the row's own UUID primary key. **This is load-bearing, not incidental:** if a push succeeds on Supabase but the app crashes before the queue row is cleared, the retry resends the same row. A plain `insert()` would then fail on the duplicate primary key and permanently stall that row. `upsert()` makes every retry safe regardless of whether a prior attempt partially succeeded.

### 4.3 Pushers (`lib/sync/pushers/`)
One class per entity (`BatchPusher`, `ExpensePusher`, `FeedPusher`, `HarvestPusher`, `MortalityPusher`, `SalePusher`, `VaccinationPusher`, `WeightSamplePusher`), implementing a shared `EntityPusher` interface. Each:
1. Reads the row's **current** state from local Drift by `recordId` at push time (never a snapshot taken when queued — relevant for Batches, where a queued `'insert'` could still be pending when `close()` later mutates the same row).
2. `upsert()`s to the matching Supabase table with the real column names.
3. Returns a `SyncPushResult`: `SyncPushSuccess`, `SyncPushDropped` (row no longer exists locally — treated as success, nothing left to push), `SyncPushFailure(error)` (retryable), or `SyncPushRejected(error)` (not retryable — only `MortalityPusher`/`HarvestPusher` can return this, matched on `PostgrestException.message.startsWith('mortality plus harvested')`).

**Design-history note:** Phase 3 originally had pushers throw exceptions; Phase 6 refactored all 8 pushers to the result-returning contract above so `SyncPushRejected` could exist as a distinct, type-safe outcome alongside `SyncPushFailure`. This was flagged as "specification drift" from the original phase-by-phase prompts but kept deliberately — the result-returning design is more explicit and more testable than throw-based control flow for a function with four meaningfully different outcomes.

### 4.4 `SyncService` (`lib/sync/sync_service.dart`)
Orchestrates one `drain()` pass:
1. Reads all `pendingRows()` (already excludes `rejected = true` rows).
2. Groups by `entityTable`, walks tables in the fixed FK-safe order (§2).
3. For each row, calls the matching pusher, then:
   - `SyncPushSuccess` / `SyncPushDropped` → `markSynced()` (deletes the queue row), stamps `syncedAt` on the source row where that column exists (not all tables have one — `batches` and `sales` don't).
   - `SyncPushFailure` → `markFailed()` (increments `attempts`, records `lastError`, row stays queued for next drain).
   - `SyncPushRejected` → `markRejected()` (sets `rejected = true`, records `lastError`, does **not** increment `attempts`, row stays queued but is excluded from future `pendingRows()`).
4. Single-flight: a `drain()` call already in progress is joined by concurrent callers rather than running twice in parallel.
5. One bad row's failure doesn't block its same-table siblings in the same pass — not awaited sequentially in a way that stalls the whole table.

### 4.5 Triggers (`lib/sync/triggers/`)
Three triggers call `SyncService.drain()`, all fire-and-forget (`unawaited`) **except** the logout path, which awaits with a timeout:

- **`ConnectivitySyncTrigger`** — listens to `connectivity_plus`'s `onConnectivityChanged` stream, drains on transition *into* a connected state (never on dropping offline). Idempotent `start()`, clean `dispose()`.
- **`LifecycleSyncTrigger`** — debounced (3s default) drain scheduler. Wired via a Riverpod listener on Drift's own update stream, filtered to **inserts only** on the `sync_queue` table — not updates or deletes, since `markSynced`/`markFailed`/`markRejected` also write that table, and letting those count would create a hot retry loop (every failed drain scheduling its own retry ~3s later, forever). This also means **zero of the 8 repository classes needed individual edits** — the original plan assumed repositories shared a provider they could hook into, but each constructs its own `LocalSyncQueueRepository` instance directly; listening at the queue-table level sidesteps that entirely.
- **Login drain** — wired into `AuthDomain.verifyLoginCode()`'s `onLoginSuccess` callback (mobile-only path, `mobile_auth_domain_provider.dart`), after the account cache write completes. **Deliberately `unawaited`**, not blocking — a field user with spotty connectivity logging back in after days offline shouldn't sit on the login screen waiting for a potentially large queue to drain; the other triggers will pick it up shortly after anyway.
- **Logout drain** — the one exception to fire-and-forget. `LogoutDomain.drainAndCountUnsyncedRows()` awaits `SyncService.drain()` with a 15-second timeout before computing the count shown in the confirmation dialog. Only `TimeoutException` is swallowed (falls through to counting whatever's actually left); any other drain error propagates to the existing screen error handling.

A connectivity event can fire before login completes (the OS reports current network state as soon as the listener attaches — common on cold start). Those pushes will 401 against Supabase (no authenticated session yet); the rows simply keep their `attempts`/`lastError` and the post-login drain retries them. Nothing is lost. Left unguarded deliberately — building a "wait for auth before allowing drain" guard is retry-policy-adjacent work, out of scope here.

### 4.6 Read-only pull / cache refresh for all 8 synced entities (the D3 exception)

**The gap this closes (found twice, same root cause):**
1. Manager assigns Staff to a batch on Manager's device. The write pushes to Supabase correctly. Staff's device, reading only its own local Drift, never learns about it — "no batches yet" forever.
2. Generalizing from there: Staff records entries (mortality, harvest, feed, etc.) that push to Supabase fine, but Manager/Admin's device — also reading only its own local Drift — never sees them either. Both are the same structural gap: this engine was push-only in every direction until this fix, and mobile UI reads *exclusively* from local Drift, so a device that didn't personally write a row had no way to ever learn it exists.

**What was built — applied to all 8 device-relevant entities** (Batches first, then generalized to Expenses, MortalityEntries, FeedEntries, WeightSamples, VaccinationEntries, HarvestEntries, Sales):
- `refreshX()` on each entity's domain class (e.g. `BatchDomain.refreshBatches()`, `ExpenseDomain.refreshExpenses()`, etc.) — same placement convention as the pre-existing `AccountDomain.refreshStaffPool()`.
- Each calls that entity's remote repository's `getAll()`: a plain `select()` (ordered by `date`, or `created_at` for Sales) against the matching Supabase table under the authenticated client, with **zero manual role/business filtering in the query** — RLS does the scoping. Confirmed directly against the real schema (not assumed) for every table:
  - `batch`, `mortality_entry`, `feed_entry`, `weight_sample`, `vaccination_entry`, `harvest_entry` share one shape: Admin/Manager get everything in their business, Staff gets only rows for batches assigned to them.
  - `expense` and `sale` are Admin/Manager-only by RLS — a Staff session's `select()` correctly returns nothing for these, by design (Staff has no visibility into financial data at any layer, not just the UI).
- Each writes via that entity's local repository's `upsertAll()` — `_db.batch(insertAllOnConflictUpdate(...))`, overwrite-the-cache semantics, same shape across all 8.

**The no-queue guarantee (important, and easy to get wrong — applies identically to all 8):** `upsertAll()` must never enqueue into `SyncQueue`. This is pull direction (Supabase → local), the exact opposite of what `enqueue()` exists for. Getting this wrong would create a pointless push-pull loop, and for rows a device has no RLS `UPDATE`/`INSERT` permission on (e.g. Staff pulling Batches, or any role pulling another device's entries), it would be actively broken — any push attempt from a pulled-then-requeued row would permanently fail. Structurally enforced by keeping `enqueue()` calls only inside the genuine local-write methods (`create`, `record`, `assignStaff`, `close`), never inside any `upsertAll()`. Tested explicitly per entity: queue state unchanged after a pull.

**A trap caught once on Batches, then deliberately guarded against on the other 7:** the first implementation's `_toCompanion()` mapping helper for Batches silently omitted `assignedStaffId`, `closedBy`, and `closedAt` — an upsert built on it would have written `NULL`/skipped those fields, silently dropping the very data the fix exists to deliver, while still "working" in the sense of not crashing. Fixed there, and the generalization to the other 7 tables started with an explicit audit pass (`_fromRow` ↔ model ↔ `_toCompanion` ↔ pusher payload ↔ `fromJson`, checked 1:1 against real column counts for every table) *before* writing any code, specifically to catch this class of bug preventively rather than after the fact. **General lesson, worth remembering for any future table: an upsert/pull mapping helper that's missing a column doesn't error — it silently drops data. Audit the full column list against the real schema every time, don't assume an existing helper is complete just because it compiles.**

**Trigger:** all 8 `refreshX()` calls happen at login, alongside the pre-existing `refreshStaffPool()` call (`mobile_auth_domain_provider.dart`), via a `pullSafely()` helper that isolates each pull — one failing pull doesn't block the others or block login itself; a failed pull simply leaves that entity's cache as it was.

**Known limitation — mid-session discovery, unchanged by the generalization:** a device that's already logged in only learns about another device's writes at its *next* login, for all 8 entities. No connectivity-triggered or periodic re-pull, no pull-to-refresh gesture anywhere in the app. **Deliberately deferred, not fixed** — see §8.8.

---

## 5. Backend (Supabase)

The production schema (already live, confirmed against the actual SQL) includes, relevant to this engine:

- **`check_batch_bird_count()` trigger** — see D1 above. Fires `before insert` on `mortality_entry` and `harvest_entry`.
- **RLS policies** scoped by role and business, matching the Flutter-side role model exactly (Staff can only insert entries for batches assigned to them; Manager-only for expenses/sales; Admin/Super Admin never touch farm data).
- **Table-level `GRANT SELECT, INSERT, UPDATE ... TO authenticated`** on every synced table. No `DELETE` grant anywhere — matches the append-only design (corrections are new entries, not edits to old ones, except Batches' `assignStaff`/`close`).
- Pushes authenticate as the device's own signed-in Supabase session (`supabaseClientProvider`'s client) — `recordedBy` already matches that account, so RLS applies the same as if the write happened directly against Supabase. No impersonation, no elevated/service-role access anywhere in this engine.

---

## 6. Implementation history (phase by phase)

| Phase | What it did | Status |
|---|---|---|
| **1** | `SyncQueue` Drift table + `LocalSyncQueueRepository` (enqueue/pendingRows/pendingCount/markSynced/markFailed) | ✅ Done |
| **2** | Wired all 8 entity repositories' write paths to `enqueue()` | ✅ Done (one gap caught and fixed: `LocalBatchRepository.create()` initially didn't enqueue — batches would never have synced at all until this was found) |
| **3** | Push engine: `SyncService`, 8 entity pushers, `upsert()`-based idempotent pushes | ✅ Done |
| **4** | `countUnsyncedRows()` rewired from counting whole tables to reading the queue | ✅ Done |
| **5** | Automatic triggers: connectivity, debounced post-write, post-login | ✅ Done |
| **6** | Server-side bird-count rejection handling (`rejected` column, `SyncPushRejected`, exclusion from auto-retry) | ✅ Done |
| **7** | Logout gating: blocking drain-with-timeout before the unsynced-row warning, method renamed to `drainAndCountUnsyncedRows()` | ✅ Done |
| **Post-7 fix 1** | Batches pull (§4.6) — closes the "Staff never sees new assignments" gap found in manual testing | ✅ Done |
| **Post-7 fix 2** | Generalized the pull to all 8 synced entities (§4.6) — closes the mirror-image gap: Manager/Admin never seeing Staff's entries | ✅ Done |
| **Post-7 fix 3** | D2 revised: logout hard-blocks on pending/failed rows, still warns-and-allows on rejected-only | ✅ Done |

**Test coverage:** 44/44 passing across `test/repository/logout_local_repository_test.dart`, `test/sync/sync_service_test.dart`, `test/sync/triggers_test.dart`, `test/domain/batch_domain_test.dart`, `test/repository/batch_local_repository_test.dart`, 7 entity repo test files, and `test/domain/expense_domain_test.dart`.

**File inventory (new/changed files across all phases):**
```
lib/data/local/tables.dart                              — SyncQueue table definition
lib/data/local/database.dart                             — schemaVersion bumps (v2 → v3), migrations
lib/data/local/local_sync_queue_repository.dart          — enqueue/pendingRows/pendingCount/markSynced/markFailed/markRejected
lib/data/local/local_{batch,expense,feed,harvest,mortality,sale,vaccination,weight}_repository.dart
                                                           — enqueue() calls wired into write paths; getById() + markSynced() added where missing
lib/sync/sync_result.dart                                 — SyncPushResult family (Success/Dropped/Failure/Rejected), SyncResult aggregate
lib/sync/sync_service.dart                                — drain() orchestrator, FK-safe push order, single-flight
lib/sync/sync_providers.dart                               — Riverpod wiring: entityPushersProvider, syncServiceProvider, trigger providers, queue-table insert listener
lib/sync/pushers/entity_pusher.dart                        — shared interface
lib/sync/pushers/{batch,expense,feed,harvest,mortality,sale,vaccination,weight}_pusher.dart
lib/sync/triggers/connectivity_sync_trigger.dart
lib/sync/triggers/lifecycle_sync_trigger.dart
lib/domain/mobile_auth_domain_provider.dart                — unawaited post-login drain
lib/domain/logout_domain.dart                              — drainAndCountUnsyncedRows() (renamed from countUnsyncedRows()), 15s-timeout blocking drain
lib/presentation/mobile/home/batch_list_screen.dart        — call-site update for the rename
lib/domain/{batch,expense,mortality,feed,weight,vaccination,harvest,sale}/*_domain.dart
                                                           — refreshX() on all 8
lib/repository/{batch,expense,mortality,feed,weight,vaccination,harvest,sale}/local_*_repository.dart
                                                           — upsertAll() (no-enqueue) on all 8; batch's _toCompanion() fixed to include assignedStaffId/closedBy/closedAt
lib/repository/{expense,mortality,feed,weight,vaccination,harvest,sale}/remote_*_repository.dart
                                                           — getAll() added on the 7 generalized to
lib/domain/mobile_auth_domain_provider.dart                 — pullSafely() helper wrapping all 8 isolated login-time pulls
lib/data/local/local_sync_queue_repository.dart              — blockingCount() (rejected=false only)
lib/repository/logout/local_logout_repository.dart           — countBlockingUnsyncedRows()
lib/domain/logout_domain.dart                                 — drainAndCountUnsyncedRows() returns {total, blocking}
lib/presentation/mobile/home/batch_list_screen.dart           — three-way logout branch: hard block / warn-and-allow / silent
test/repository/logout_local_repository_test.dart
test/sync/sync_service_test.dart
test/sync/triggers_test.dart
test/domain/batch_domain_test.dart
test/domain/expense_domain_test.dart
test/repository/{batch,expense,mortality,feed,weight,vaccination,harvest,sale}_local_repository_test.dart
```

---

## 7. Implementation gotchas worth remembering

**Drift reserved-name collision (`tableName`).** The queue table's "which table does this row belong to" column was originally specified as `tableName`. Drift's base `Table` class has its own reserved `tableName` getter (overrides the SQL table name). A column with that exact name collides with it and breaks code generation in ways that cascade into dozens of unrelated-looking errors (invalid overrides, mismatched generated data-class types, the works) rather than one clear error. Fixed by renaming to `entityTable`. **For any future Drift table: avoid column names that shadow members of Drift's own base classes** (`tableName`, `actualTableName`, etc.) — the failure mode is confusing enough that it's worth checking proactively rather than discovering it in `flutter analyze` output.

**Generated data-class naming.** For a Drift table class `Foo extends Table` where `Foo` doesn't end in `s`, the generated row data class is `FooData`, not `Foo` — Drift can't name the row class the same as the table class, so it appends `Data` to disambiguate when there's no trailing-s to strip (contrast: `Users extends Table` → row class `User`). `SyncQueue` → `SyncQueueData`. Got this wrong once mid-implementation (a stray local redefinition of `SyncQueueData` inside the repository file, shadowing the real generated one) — resolved by deleting the local definition and using the generated type directly.

---

## 8. Known gaps / open items for future phases

These are not oversights — each was identified during development and deliberately deferred rather than silently left out. Listed here so the next phase of work starts from an accurate picture, not a rediscovery.

1. **No retry/backoff policy.** A failed (non-rejected) push just sits in the queue until the next trigger fires, with no cap and no exponential delay. A persistently-failing row (e.g. sustained RLS misconfiguration, not a bird-count rejection) will be retried on every connectivity blip and every debounced write indefinitely. Needs a decision: capped retries with backoff and a "give up, surface to user" path, or accept indefinite retry as acceptable since farm data should never be silently dropped.

2. **No UI to review or resolve rejected rows.** A bird-count-rejected row (D5) sits in the queue forever with `rejected = true` and a `lastError` message, visible nowhere in the app except direct database inspection. It still correctly counts toward the logout warning, but a user has no way to understand *why* a row is stuck or take any corrective action from within the app. This is the most user-facing gap of the list.

3. **Trigger message matching is string-prefix based, unverified against a live rejection.** `MortalityPusher`/`HarvestPusher` detect a bird-count rejection by checking `PostgrestException.message.startsWith('mortality plus harvested')`, inferred from the trigger's SQL source rather than confirmed against an actual thrown exception from the live database. Should be verified the first time this trigger genuinely fires in practice (deliberately construct the two-device-conflict scenario against a real Supabase instance) — if Supabase wraps or truncates the message differently than expected, this match silently fails and a genuine rejection falls through to the generic `SyncPushFailure` retry path instead, defeating D5.

4. **15-second logout timeout is hardcoded.** Not yet promoted to a named/configurable constant. Low priority until there's a real reason to tune it.

5. **No pull/merge (D3), confirmed non-goal for this version** but worth flagging explicitly for next-version planning: if the product ever needs genuinely concurrent multi-device editing (not just "two offline devices eventually both sync"), this engine's push-only design does not extend to that without a real redesign — conflict resolution for simultaneous edits to the same row is a different problem than this engine solves.

6. **No background sync (D4), confirmed non-goal.** If there's ever a requirement for sync to happen while the app isn't open (e.g. scheduled background push even when a staff member hasn't opened the app in days), that's new platform-level work (WorkManager/BackgroundFetch), not an extension of the current trigger set.

7. **Connectivity-before-login races are unguarded.** Noted in §4.5 — harmless (rows just retry after login) but technically means the connectivity trigger can fire unauthenticated requests against Supabase before a session exists. Not a bug, but worth knowing about if request logs ever need explaining.

8. **All 8 entity pulls are login-only — no mid-session discovery.** A device that's already logged in when another device's write lands on Supabase won't see it until it next logs in — true for Batches (Staff missing a new assignment) and for all 7 entry/financial tables (Manager/Admin missing Staff's newly-recorded entries). No connectivity-triggered re-pull, no periodic refresh, no pull-to-refresh gesture anywhere in the app (confirmed absent, not added). Deliberately deferred rather than bolted onto the existing connectivity trigger, since that trigger exists specifically to drain the *push* queue and mixing an unrelated pull into it would muddy what "connectivity regained" means for future debugging. If this becomes a real usability problem (long-running sessions missing same-day updates from other devices), the fix is either a pull-to-refresh gesture on the relevant list screens, or a separate, clearly-named connectivity-triggered pull call kept distinct from `ConnectivitySyncTrigger`.

9. **The `_toCompanion()` missing-column trap (§4.6) is a pattern to watch for generally**, not just a one-time bug. Any upsert/pull mapping helper that's missing a column doesn't throw — it silently drops that field's data on every write through it. Worth an explicit audit (mapped fields vs. actual table schema, side by side) any time such a helper is written or reused for a new entity, rather than trusting it compiles correctly.
