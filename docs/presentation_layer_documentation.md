# broiler_fms — Presentation Layer Documentation

The entire Presentation layer is built: both platforms, all four
roles, every screen in the Phase 2 plan. This document records what
exists, the real decisions made while building it, and what is
deliberately left open before Sync Engine and end-to-end testing.

---

## 1. What exists, by platform

### Mobile (Staff, Manager) — `lib/presentation/mobile/`

```
✅ Login (email → code)
✅ Batch list (role-aware: Staff sees assigned, Manager sees all)
✅ Batch detail (stat cards, close-batch, action rows)
✅ Record mortality / feed / harvest / weight / vaccination
✅ Register batch                    (Manager)
✅ Assign staff                      (Manager)
✅ Log expense                       (Manager)
✅ Price a harvest (list → price)    (Manager)
✅ Financial summary                 (Manager)
```

Entry point: `lib/main.dart`. Router: `lib/presentation/mobile/router.dart`.

### Web (Admin, Super Admin) — `lib/presentation/web/`

```
✅ Login (email → code, same AuthDomain as mobile, unchanged)
✅ Register business (shown instead of a dashboard when businessId is null)
✅ Overview + Edit business          (Admin)
✅ Accounts: Manager panel + Staff table, add/deactivate/reactivate (Admin)
✅ Batches (list) + Batch view (financial summary)     (Admin, read-only)
✅ Admin accounts: the entirety of Super Admin's app   (Super Admin)
```

Entry point: `lib/main_web.dart`. Router: `lib/presentation/web/router.dart`.

### Shared — `lib/presentation/shared/`

```
app_theme.dart       — colors, fonts, lifted directly from the mockups
widgets/badge.dart        — status pill, tone decided by the caller
widgets/stat_card.dart    — the 3-up number cards, used on every stats screen
widgets/confirm_dialog.dart — are-you-sure pattern, used 6+ times
widgets/review_step.dart    — form-then-review pattern, used 7+ times
```

---

## 2. Real decisions made while building this layer

### 2.1 One route tree per platform, not one shared tree

Mobile and web each get their own `GoRouter` instance and entry point
(`main.dart` / `main_web.dart`), matching the original architecture
decision that mobile is offline-first through Drift and web talks to
Supabase directly. Within each tree, roles share routes rather than
getting separate trees — Staff and Manager both use `batch_list_screen.dart`
and `batch_detail_screen.dart`, with role checked internally to decide
what's shown.

### 2.2 Redirect guards, not one-time checks

Both routers' `redirect` functions re-run on every navigation attempt,
not just once after login. This matters concretely for the business
guard: an Admin can close the app mid-registration and reopen later,
without logging in again, and still needs to land back on
`/register-business`, not a broken dashboard. A one-time post-login
check would miss this case entirely.

### 2.3 `ref.invalidate(currentAccountProvider)` after every state change that affects it

`currentAccountProvider` is a `FutureProvider`, cached until told
otherwise. Three places explicitly invalidate it: both platforms'
`../../../../../../../home/yaawaleed/Downloads/code_screen.dart` (right after login succeeds) and
`register_business_screen.dart` (right after `businessId` changes from
null to something real). Without this, the router's guards would act
on stale cached data at the exact moments correctness matters most.

### 2.4 `ShellRoute` for web's persistent sidebar, flat routes for everything else

Admin's screens live inside `AdminShell` via `ShellRoute`, which keeps
the sidebar mounted while swapping content underneath it. Super
Admin's single page is a flat route with no shell at all, matching
the mockup's explicit absence of a sidebar for that role. `/` itself
branches by role in the redirect function: Admin is redirected to
`/overview` (inside the shell), Super Admin's `/` is
`AdminAccountsScreen` directly.

### 2.5 Mobile's record-entry screens all follow one template

Mortality, feed, harvest, weight, and vaccination forms share an
identical shape: `TextEditingController`s, a `_showingReview` bool
flipping between form and `ReviewStep`, a `try/on DomainException/finally`
block, `context.pop()` on success. This was deliberate — once mortality
was built and proven, the other four were direct copies with different
fields, not reinvented each time.

### 2.6 Presentation computes role-dependent lists itself, not Domain

`_visibleBatchesProvider` (mobile batch list) and the staff-count /
manager-status / pending-invite figures (web overview) are computed in
Presentation from data Domain already returns, rather than adding new
narrow Domain methods for each one. This matches the project's
standing rule: Domain has no concept of role, so "what does this
specific screen need to show" stays a Presentation concern.

---

## 3. Gaps and deliberate simplifications, left open on purpose

These were each flagged at the point they came up, not missed
silently. Listed here together so they're easy to find later.

- **Business profile fields can't be cleared back to empty.**
  `RemoteBusinessRepository.updateProfile` only writes a field when
  it's non-null (the fix for the very first bug found in this entire
  project). Consequence: once a field like phone is set, there is
  currently no way to clear it back to empty through
  `edit_business_screen.dart`. Fixing this requires a repository-level
  decision (a sentinel value, or a separate "clear" signal), not a
  Presentation-only patch.
- **Deactivating Staff doesn't name affected batches.** The original
  spec described naming which batches would need reassignment when
  deactivating a Staff member. The built version uses a generic
  warning instead, since doing this properly needs a new
  `RemoteBatchDomain` method to cross-reference batches against an
  account id, which doesn't exist yet.
- **Expense form has no chicks-category quantity auto-fill.** The
  mockup pre-fills and disables a quantity field from the batch's
  starting bird count for the `chicks` category. The built version
  omits the field entirely for that category, since
  `ExpenseDomain.recordExpense` treats quantity as fully optional
  regardless of category.
- **`assign_staff_screen.dart` calls `watchStaffPool` directly inside
  `build()`** rather than through a proper `.family` `StreamProvider`,
  unlike every other list in the app. Functionally correct, since
  `StreamBuilder` handles resubscription fine, but inconsistent with
  the pattern used everywhere else.
- **`BatchDomain`'s financial and total-count methods are a real N+1
  pattern.** `getFinancialSummary`, `getTotalMortality`,
  `getTotalHarvested`, and `getRemainingBirdCount` each re-fetch and
  re-sum raw entries on every call, with no caching. Fine at local
  SQLite scale; worth knowing before this is ever used against a much
  larger dataset.
- **No `watchById` for a single batch.** `batch_detail_screen.dart`
  cannot react automatically to a batch changing while open (e.g.
  another device closing it); it only refreshes after this device's
  own `closeBatch` action, via explicit `ref.invalidate(...)`.

---

## 4. What is still outside this layer entirely

- **Sync Engine** — explicitly deferred since the very start of this
  project. Nothing built in Presentation or Domain depends on it
  existing yet; every mobile write so far only ever reaches local
  SQLite.
- **Tests** — still none written anywhere in the project. The
  pure functions in `domain/rules/` remain the easiest starting point,
  needing no fakes, mocks, or widget setup at all.
- **The font-loading decision** (bundled `.ttf` files via
  `pubspec.yaml`) is implemented and working, but depends on the
  actual font files having been placed in `assets/fonts/` correctly —
  worth a visual check once the app is actually run, not just analyzed.

---

## 5. Suggested next step

The original plan's own words, from the message that kicked off this
entire phase: *"after that, then we can test and see if there's
anything, any flaws in the domain, maybe, or anything there."*

With both Presentation trees now complete, that testing phase is what
comes next — actually running the app (mobile via `flutter run`, web
via `flutter run -t lib/main_web.dart -d chrome`), walking through each
role's real flows end to end, and letting whatever breaks surface
Domain issues the planning and `flutter analyze` alone couldn't catch.
Only after that does Sync Engine begin.
