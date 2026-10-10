# broiler_fms — Domain Layer Documentation

This document explains the Domain layer built for the Broiler Farm
Management System: what it is, why each piece exists, and the design
decisions made along the way. It is written as a reference for
maintaining and extending the app later, not as a tutorial.

---

## 1. What the Domain layer is for

The app is split into four layers, each one only talking to the layer
directly below it:

```
Presentation  (screens, buttons)
     ↓
Domain        (rules, decisions)
     ↓
Repository    (talks to storage)
     ↓
Data          (Drift / Supabase)
```

Repository knows *how* to save or fetch something. It does not know
*whether* an action is allowed. That judgment is Domain's job. A
screen never touches Drift or Supabase directly, and never holds a
repository — it only ever calls a Domain class.

This separation exists because mobile (Staff, Manager) and web (Admin,
Super Admin) use genuinely different storage: mobile is offline-first
through Drift, web talks to Supabase directly with no local database.
Domain is what lets a screen call `harvestDomain.recordHarvest(...)`
without knowing or caring which storage sits underneath.

---

## 2. Final folder structure

```
lib/domain/
├── domain_exception.dart
├── current_account_domain.dart
├── rules/
│   ├── bird_count_rule.dart
│   ├── batch_closure_rule.dart
│   ├── sale_shape_rule.dart
│   └── expense_category_rule.dart
├── harvest/
│   ├── harvest_domain.dart
│   └── remote_harvest_domain.dart
├── batch/
│   ├── batch_domain.dart
│   └── remote_batch_domain.dart
├── mortality/
│   ├── mortality_domain.dart
│   └── remote_mortality_domain.dart
├── sale/
│   ├── sale_domain.dart
│   └── remote_sale_domain.dart
├── feed/
│   ├── feed_domain.dart
│   └── remote_feed_domain.dart
├── weight/
│   ├── weight_domain.dart
│   └── remote_weight_domain.dart
├── vaccination/
│   ├── vaccination_domain.dart
│   └── remote_vaccination_domain.dart
├── expense/
│   ├── expense_domain.dart
│   └── remote_expense_domain.dart
├── account/
│   ├── account_domain.dart           (mobile: read-only cache access)
│   └── remote_account_domain.dart    (web: create, status changes)
└── business/
    └── business_domain.dart          (web only, no local side)
```

Nine entities get a mobile/web pair. Business is the one exception,
with no local side at all, because Manager and Staff never touch
business data.

---

## 3. Design decisions and the reasoning behind each

### 3.1 One class per entity, not one function per action

Considered alternative: a separate small file per action (`record_harvest.dart`,
`close_batch.dart`, etc.). Rejected because with ten entities and
several actions each, this would produce 30+ tiny files — more than
the repository layer itself has folders. One class per entity mirrors
`repository/` and `domain/models/` exactly, so "everything about
harvest" stays one predictable lookup away across all three layers.

### 3.2 Pure rule functions, separate from the classes that call repositories

`rules/` holds functions that decide but never fetch data themselves —
`canRecordBirdCount`, `canCloseBatch`, `saleShapeError`,
`expenseCategoryError`. Each one takes plain numbers or strings in and
returns a bool or a message out. This keeps them trivially testable
with no database setup, and keeps the `*_domain.dart` files focused on
coordination (fetch totals, call the rule, write) rather than mixing
decision logic with repository calls.

Each device-side rule mirrors a real CHECK constraint or trigger
already in `schema.sql`. The device check exists to give instant
feedback the moment Staff or Manager types a number in, rather than
waiting for a sync round-trip to discover the entry was invalid.
Postgres remains the real backstop in every case — the device check is
a convenience, not the only enforcement.

### 3.3 Why Account needed a local, read-only cache

Originally, Account was remote-only: no local repository, mobile read
it directly over the network. This was reversed once it became clear
that Manager needs to pick a Staff member to assign to a batch even
with no connectivity — the Staff pool had to be readable offline.

`LocalAccountRepository` is a **read-only cache**, not a full local
repository like the other nine. Mobile never creates or edits an
Account; Postgres's own RLS already forbids it for Manager and Staff.
The only way data enters the cache is `upsertAll`, which overwrites
wholesale with whatever Supabase last said. There is nothing to
reconcile and no write conflict to resolve, which is why this does not
need the sync queue machinery the other nine entities will eventually
use.

### 3.4 `CurrentAccountDomain` — resolving "who is using this device"

This solves a problem that existed from the start but wasn't visible
until harvest's `recordedBy` field was examined closely: every mobile
write needs to know who is recording it, and that has to work offline.

- `resolveAndCacheMyAccount()` runs once, right after login (while
  there is definitely connectivity). It pulls the signed-in user's own
  account from Supabase, and if they are a Manager, their Staff pool
  too, then writes both into the local cache.
- `getCurrentAccount()` runs everywhere else. It reads
  `Supabase.auth.currentUser?.id` (already persisted locally by
  `supabase_flutter`, no network needed) and looks that up in the
  local cache. Returns null if nobody has ever logged in on this
  device, or the cache was cleared on logout.

Every mobile `*Domain` constructor now requires `Account currentAccount`.
`recordedBy` (and `closedBy`) is never a parameter on any write
method — it is always `_currentAccount.accountId`, resolved once when
the class is built, never retyped or passed by hand.

### 3.5 Error handling: one exception type, not a Result wrapper

`DomainException` is the only thing any Domain class throws when a
rule fails. It carries a `message` already written for a real person
to read. Presentation catches `DomainException` and shows `.message`
directly, no translation needed. Anything else thrown (a Drift
exception, a network timeout) is treated as an unexpected error, not a
validation failure.

A `Result<T, E>` wrapper type was considered and rejected as
unnecessary complexity for a project this size — plain try/catch in
Presentation is idiomatic enough here.

### 3.6 Riverpod: hand-written providers, not code generation

Each repository and each Domain class gets exactly one provider,
living at the bottom of the same file as the class it builds — not in
a separate central `providers/` folder. This keeps the same
one-folder-per-entity legibility already established by `repository/`
and `domain/`, rather than introducing a second organizing idea just
for wiring.

Two foundational providers sit outside any entity folder, since
nothing entity-specific depends on them existing first:

- `appDatabaseProvider` (`data/local/database_provider.dart`) — the
  single shared Drift instance. **Mobile only.** Must never be
  imported from anything reachable by the web build, since
  `database.dart` itself imports `dart:io`.
- `supabaseClientProvider` (`data/remote/supabase_provider.dart`) —
  shared by both platforms.

### 3.7 Why local and remote repositories/domains are always separate files

`database.dart` imports `dart:io` and `package:drift/native.dart`,
neither of which exist on web. If a local and remote class for the
same entity ever shared a file, the web build would import that file
for the remote half and drag the local half's `dart:io` dependency in
behind it, breaking compilation. This rule shows up at every layer:
repositories, domains, and providers all keep local and remote strictly
apart, file by file.

### 3.8 The Drift / model naming collision

Drift auto-generates a row class per table, normally by stripping the
trailing "s" from the table name (`Batches` → `Batch`). Several of
these collide with hand-written model classes of the same name. Two
things resolve this together:

- `import 'package:broiler_fms/data/local/database.dart' as local;` in
  every local repository, so Drift's generated class becomes
  `local.Batch` while the hand-written model stays plain `Batch`.
- An explicit `@DataClassName('X')` annotation on any table where
  Drift's automatic guess would be wrong (`Businesses`, `Batches`,
  `Accounts` all needed this; `Sales` → `Sale` and most others did
  not).

---

## 4. Entity-by-entity summary

| Entity | Bird-count rule? | Other rule | Who writes (mobile) | Notes |
|---|---|---|---|---|
| Harvest | Yes | Batch must be open | Staff | |
| Mortality | Yes | Batch must be open | Staff | Shares bird-count totals with Harvest |
| Batch | No | Must be fully accounted for to close | Manager | Only entity with a `create` action |
| Sale | No | `sale_shape`, amount-matches-weight-price | Manager | Prices a Harvest; enforces one-sale-per-harvest |
| Feed | No | Batch must be open | Staff | |
| Weight | No | Batch must be open | Staff | |
| Vaccination | No | Batch must be open | Staff | |
| Expense | No | Batch must be open, valid category | Manager | Staff never sees this repository at all |
| Account | — | — | — | Mobile side is read-only cache access, never writes |
| Business | — | — | Admin (web only) | No local side at all |

---

## 5. What was deliberately left open or deferred

These were identified during the build and intentionally not solved
here, either because they belong to a later stage or because they
need a decision this document does not make for you:

- **Role checking in Domain.** Domain does not check which role is
  calling it. SQLite has no concept of "who's logged in," and a
  modified client could bypass any device-side check regardless.
  Supabase RLS remains the real backstop on sync. Presentation decides
  which actions are even exposed per role.
- **`currentAccountProvider` loading vs. null.** Being a
  `FutureProvider`, `.value` is `null` both while still resolving and
  if genuinely nobody is signed in. Every `*DomainProvider` currently
  throws the same generic exception in both cases. Distinguishing them
  is left for Presentation, once login and routing exist.
- **Cross-device bird-count races.** The bird-count and batch-closure
  rules only protect a single device against itself. Two offline
  devices writing to the same batch can each pass the local check
  using stale totals; Postgres's own trigger is the real backstop for
  that case.
- **Atomic multi-table writes.** No Domain action built so far needs
  a true multi-table transaction (several of them read from multiple
  repositories, but each only ever writes to one). If one is needed
  later, a Drift transaction would need to live on `AppDatabase`
  itself.
- **Tests.** No test file exists yet. The pure functions in `rules/`
  are the easiest starting point, needing no fakes or mocks at all.
- **Sync Engine (the push side).** Explicitly out of scope for this
  layer, built last, after Presentation.

---

## 6. Build order actually followed

1. `RemoteAccountRepository.getMyAccount`
2. `LocalAccountRepository` (new file, read-cache shaped)
3. `domain_exception.dart`
4. `current_account_domain.dart`
5. Foundational providers (`appDatabaseProvider`, `supabaseClientProvider`)
6. Harvest, Batch, Mortality — rewired to `currentAccount`
7. Sale, with `sale_shape_rule.dart`
8. Feed, Weight, Vaccination, Expense
9. Account's own `account_domain.dart` / `remote_account_domain.dart`
10. `business_domain.dart`

Presentation begins next.
