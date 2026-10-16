-- ============================================================
-- Broiler Farm Management System — Corrected Schema + RLS
-- Run this once, top to bottom, in the Supabase SQL editor.
-- This replaces the earlier draft in full; every fix below is
-- commented so the reasoning stays visible for defense.
-- ============================================================

create extension if not exists pgcrypto;

-- ============================================================
-- 1. TABLES
-- ============================================================

create table public.business (
  business_id     uuid primary key default gen_random_uuid(),
  name            text not null,
  address         text,
  phone           text,
  business_type   text,
  description     text,
  created_at      timestamptz not null default now()
);

create table public.account (
  account_id      uuid primary key default gen_random_uuid(),
  -- FIX: business_id is now nullable. Super Admin has no business
  -- at all, and a freshly-invited Admin has none until they
  -- register one. A NOT NULL here made both cases impossible to
  -- insert, which would have blocked account creation entirely.
  business_id     uuid references public.business(business_id),
  auth_user_id    uuid unique references auth.users(id),
  role            text not null check (role in ('super_admin','admin','manager','staff')),
  name            text not null,
  email           text not null unique,
  status          text not null default 'pending' check (status in ('pending','active','inactive')),
  created_at      timestamptz not null default now()
);

create table public.batch (
  batch_id              uuid primary key default gen_random_uuid(),
  business_id           uuid not null references public.business(business_id),
  assigned_staff_id     uuid references public.account(account_id),
  closed_by             uuid references public.account(account_id),
  batch_name            text not null,
  breed                 text,
  description           text,
  starting_bird_count   integer not null check (starting_bird_count > 0),
  start_date            date not null,
  is_closed             boolean not null default false,
  created_at            timestamptz not null default now(),
  closed_at             timestamptz
);

create table public.expense (
  expense_id       uuid primary key default gen_random_uuid(),
  batch_id         uuid not null references public.batch(batch_id),
  recorded_by      uuid not null references public.account(account_id),
  -- FIX: category had no CHECK at all, every other classified
  -- column in this schema (role, status, disposition) does.
  category         text not null check (category in ('chicks','feed','vet_medication','other')),
  date             date not null,
  quantity         numeric,
  unit_price       numeric,
  amount           numeric not null check (amount > 0),
  feed_type        text,
  medication_name  text,
  description      text,
  recorded_at      timestamptz not null default now(),
  synced_at        timestamptz not null default now()
);

create table public.mortality_entry (
  mortality_id   uuid primary key default gen_random_uuid(),
  batch_id       uuid not null references public.batch(batch_id),
  recorded_by    uuid not null references public.account(account_id),
  date           date not null,
  -- FIX (requested): mortality can never be logged as zero. If
  -- nothing died that day, no entry is made at all — the absence
  -- of a row is what "zero" means, so this must start from 1.
  count          integer not null check (count >= 1),
  description    text,
  recorded_at    timestamptz not null default now(),
  synced_at      timestamptz not null default now()
);

create table public.feed_entry (
  feed_entry_id  uuid primary key default gen_random_uuid(),
  batch_id       uuid not null references public.batch(batch_id),
  recorded_by    uuid not null references public.account(account_id),
  date           date not null,
  -- FIX: quantity had no positivity check, inconsistent with
  -- bird_count and sample_count elsewhere in this same file.
  quantity       numeric not null check (quantity > 0),
  recorded_at    timestamptz not null default now(),
  synced_at      timestamptz not null default now()
);

create table public.weight_sample (
  weight_sample_id  uuid primary key default gen_random_uuid(),
  batch_id          uuid not null references public.batch(batch_id),
  recorded_by       uuid not null references public.account(account_id),
  date              date not null,
  -- FIX: sample_weight had no positivity check, right next to
  -- sample_count which already had one.
  sample_weight     numeric not null check (sample_weight > 0),
  sample_count      integer not null check (sample_count > 0),
  recorded_at       timestamptz not null default now(),
  synced_at         timestamptz not null default now()
);

create table public.vaccination_entry (
  vaccination_id  uuid primary key default gen_random_uuid(),
  batch_id        uuid not null references public.batch(batch_id),
  recorded_by     uuid not null references public.account(account_id),
  date            date not null,
  vaccine_name    text not null,
  recorded_at     timestamptz not null default now(),
  synced_at       timestamptz not null default now()
);

create table public.harvest_entry (
  harvest_id     uuid primary key default gen_random_uuid(),
  batch_id       uuid not null references public.batch(batch_id),
  recorded_by    uuid not null references public.account(account_id),
  date           date not null,
  bird_count     integer not null check (bird_count > 0),
  recorded_at    timestamptz not null default now(),
  synced_at      timestamptz not null default now()
);

create table public.sale (
  sale_id          uuid primary key default gen_random_uuid(),
  harvest_id       uuid not null references public.harvest_entry(harvest_id),
  recorded_by      uuid not null references public.account(account_id),
  disposition      text not null check (disposition in ('sale','gift_cull')),
  buyer_name       text,
  pricing_method   text check (pricing_method in ('per_kg','flat_total')),
  weight_sold      numeric,
  price_per_unit   numeric,
  amount           numeric not null check (amount >= 0),
  -- FIX: payment_status is now nullable, since a gift/cull has no
  -- payment at all. The composite check below is what actually
  -- enforces correctness, not the column's own NOT NULL.
  payment_status   text check (payment_status in ('paid','pending')),
  created_at       timestamptz not null default now(),

  -- FIX: nothing previously stopped a gift/cull row from also
  -- carrying a price and a payment status, or a sale row from
  -- carrying neither. This ties disposition to what the rest of
  -- the row is allowed to look like, matching the actual design:
  -- a gift/cull has zero amount and no pricing method or payment
  -- status; a sale must have both.
  --
  -- NEWLY ADDED FIX: the constraint above only tied disposition to
  -- the rest of the row, it never tied pricing_method to weight_sold
  -- and price_per_unit the same way. Nothing stopped a per_kg sale
  -- from having a null weight_sold (making amount mathematically
  -- meaningless), or a flat_total sale from carrying a leftover
  -- weight_sold it should never have. Replaced with sale_shape
  -- below, which enforces both layers at once: per_kg requires a
  -- real weight and a real price per kg, flat_total forbids weight
  -- entirely and treats price_per_unit (price per bird) as the one
  -- genuinely optional field, matching "sometimes 7,500 each,
  -- sometimes just 80,000 for the lot."
  constraint sale_shape check (
    (
      disposition = 'gift_cull'
      and pricing_method is null
      and weight_sold is null
      and price_per_unit is null
      and payment_status is null
      and amount = 0
    )
    or
    (
      disposition = 'sale'
      and payment_status is not null
      and amount > 0
      and (
        (pricing_method = 'per_kg' and weight_sold is not null and weight_sold > 0
          and price_per_unit is not null and price_per_unit > 0)
        or
        (pricing_method = 'flat_total' and weight_sold is null
          and (price_per_unit is null or price_per_unit > 0))
      )
    )
  )
);

-- ============================================================
-- 2. AUTH LINKING TRIGGER
-- Fills auth_user_id on the matching Account row the moment
-- someone completes their first OTP login. SECURITY DEFINER so
-- it bypasses RLS, since a normal Admin-only UPDATE policy would
-- otherwise block this system-level write.
-- ============================================================

create or replace function public.link_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- FIX: matched on exact email before, which is case-sensitive
  -- in Postgres. A single-character case mismatch between the
  -- invited email and the sign-in email would have silently left
  -- auth_user_id unset forever, with no error raised anywhere.
  update public.account
  set auth_user_id = new.id
  where lower(email) = lower(new.email)
    and auth_user_id is null;
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.link_auth_user();

-- Extra safety: once auth_user_id is set, nothing (not even Admin,
-- not even a bug in application code) can silently overwrite it.
create or replace function public.protect_auth_user_id()
returns trigger
language plpgsql
as $$
begin
  if old.auth_user_id is not null and new.auth_user_id is distinct from old.auth_user_id then
    raise exception 'auth_user_id cannot be changed once set';
  end if;
  return new;
end;
$$;

create trigger protect_account_auth_user_id
before update on public.account
for each row execute function public.protect_auth_user_id();

-- ============================================================
-- 3. BUSINESS RULE TRIGGER
-- FIX: this rule was decided very early in the design (mortality
-- + harvested must never exceed a batch's starting bird count)
-- but never actually appeared anywhere in the schema. Without
-- this, nothing stops a bad write, from a bug or a hand-edit,
-- from pushing a batch's totals past what's physically possible.
-- ============================================================

create or replace function public.check_batch_bird_count()
returns trigger
language plpgsql
as $$
declare
  v_starting          integer;
  v_total_mortality   integer;
  v_total_harvested   integer;
begin
  select starting_bird_count into v_starting
  from public.batch where batch_id = new.batch_id;

  select coalesce(sum(count), 0) into v_total_mortality
  from public.mortality_entry where batch_id = new.batch_id;

  select coalesce(sum(bird_count), 0) into v_total_harvested
  from public.harvest_entry where batch_id = new.batch_id;

  -- include the row currently being inserted in the total
  if tg_table_name = 'mortality_entry' then
    v_total_mortality := v_total_mortality + new.count;
  elsif tg_table_name = 'harvest_entry' then
    v_total_harvested := v_total_harvested + new.bird_count;
  end if;

  if v_total_mortality + v_total_harvested > v_starting then
    raise exception
      'mortality plus harvested (%) cannot exceed this batch''s starting bird count (%)',
      v_total_mortality + v_total_harvested, v_starting;
  end if;

  return new;
end;
$$;

create trigger check_bird_count_on_mortality
before insert on public.mortality_entry
for each row execute function public.check_batch_bird_count();

create trigger check_bird_count_on_harvest
before insert on public.harvest_entry
for each row execute function public.check_batch_bird_count();

-- NEWLY ADDED FIX (note, not code — this belongs in the app, not
-- the schema): this trigger only runs once a row actually reaches
-- Supabase. The app is offline-first, so Staff can log several
-- mortality or harvest entries over several days with no
-- connectivity, and none of them get checked against each other
-- until the device finally reconnects and syncs. If one entry in
-- that queue would push the running total past the batch's
-- starting count, this trigger throws days after Staff typed it,
-- with no memory of which entry caused it.
--
-- The fix belongs in the Domain layer on the device: recompute
-- remaining = starting_bird_count − (all mortality entries the
-- device knows about, synced or not) − (all harvest entries the
-- device knows about, synced or not), and reject on the spot, the
-- moment Staff types the number in. This trigger stays as the
-- backstop for what a single device genuinely can't see, two
-- different devices, both offline, both writing to the same batch.

-- ============================================================
-- 4. BUSINESS REGISTRATION FUNCTION
-- FIX: Admin registering their own business is a chicken-and-egg
-- problem for ordinary RLS policies — the account's business_id
-- has to change from null to the new business's id, but a normal
-- UPDATE policy checks business_id against itself, which is null
-- on both sides before this happens, so it can never pass. This
-- function performs both writes atomically as one trusted step.
-- ============================================================

create or replace function public.register_business(
  p_name text,
  p_address text default null,
  p_phone text default null,
  p_business_type text default null,
  p_description text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_account_id   uuid;
  v_role         text;
  v_business_id  uuid;
  v_new_business_id uuid;
begin
  select account_id, role, business_id
  into v_account_id, v_role, v_business_id
  from public.account
  where auth_user_id = auth.uid();

  if v_role is distinct from 'admin' then
    raise exception 'only an admin can register a business';
  end if;

  if v_business_id is not null then
    raise exception 'this admin has already registered a business';
  end if;

  insert into public.business (name, address, phone, business_type, description)
  values (p_name, p_address, p_phone, p_business_type, p_description)
  returning business_id into v_new_business_id;

  update public.account
  set business_id = v_new_business_id
  where account_id = v_account_id;

  return v_new_business_id;
end;
$$;

-- ============================================================
-- 5. HELPER FUNCTIONS
-- SECURITY DEFINER so they can read Account without recursing
-- into Account's own RLS policies while evaluating them.
-- ============================================================

create or replace function public.current_account_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select account_id from public.account where auth_user_id = auth.uid();
$$;

create or replace function public.current_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from public.account where auth_user_id = auth.uid();
$$;

create or replace function public.current_business_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select business_id from public.account where auth_user_id = auth.uid();
$$;

-- ============================================================
-- 6. ROW LEVEL SECURITY
-- ============================================================

alter table public.business enable row level security;
alter table public.account enable row level security;
alter table public.batch enable row level security;
alter table public.expense enable row level security;
alter table public.mortality_entry enable row level security;
alter table public.feed_entry enable row level security;
alter table public.weight_sample enable row level security;
alter table public.vaccination_entry enable row level security;
alter table public.harvest_entry enable row level security;
alter table public.sale enable row level security;

-- ---------- business ----------

create policy "view own business"
on public.business for select
using (business_id = public.current_business_id());

-- Ordinary insert is intentionally not allowed here — creating a
-- business goes through register_business() above, not a direct
-- insert, since it must happen together with updating the calling
-- Admin's own account row.

-- FIX: an UPDATE policy never existed for business at all, so
-- "Edit Business Profile" (a real screen in the Admin app) had no
-- way to actually work.
create policy "admin updates own business"
on public.business for update
using (
  public.current_role() = 'admin'
  and business_id = public.current_business_id()
)
with check (
  public.current_role() = 'admin'
  and business_id = public.current_business_id()
);

-- ---------- account ----------

-- FIX: previously one blanket policy scoped everything to
-- current_business_id(), which is null for Super Admin, so Super
-- Admin could never see the Admin accounts it's supposed to
-- manage. Split by who's allowed to see what.
create policy "view accounts"
on public.account for select
using (
  (public.current_role() = 'super_admin' and role = 'admin')
  or (public.current_role() in ('admin','manager') and business_id = public.current_business_id())
  or (account_id = public.current_account_id())
);

-- FIX: previously allowed 'super_admin' and 'admin' to insert
-- almost anything scoped to current_business_id(), which is null
-- for Super Admin — meaning Super Admin's very first action
-- (adding an Admin) would have been silently rejected, since
-- null = null evaluates to null, not true, in SQL.
create policy "super admin adds admin, admin adds staff or manager"
on public.account for insert
with check (
  (public.current_role() = 'super_admin' and role = 'admin' and business_id is null)
  or
  (public.current_role() = 'admin' and role in ('manager','staff') and business_id = public.current_business_id())
);

-- FIX: split for the same reason as the SELECT policy above —
-- Super Admin deactivating/reactivating an Admin can't be scoped
-- by current_business_id(), since Super Admin has none.
create policy "super admin manages admin accounts"
on public.account for update
using (public.current_role() = 'super_admin' and role = 'admin')
with check (public.current_role() = 'super_admin' and role = 'admin');

create policy "admin manages staff and manager accounts"
on public.account for update
using (
  public.current_role() = 'admin'
  and role in ('manager','staff')
  and business_id = public.current_business_id()
)
with check (
  public.current_role() = 'admin'
  and role in ('manager','staff')
  and business_id = public.current_business_id()
);

-- No delete policy anywhere in this file: this system never
-- deletes accounts, only deactivates them via the status column.

-- ---------- batch ----------

-- FIX: previously scoped only by business_id with no role check,
-- meaning Staff could read every batch in the business, not just
-- their own — directly contradicting "Staff shall view only
-- their assigned batch(es)". Super Admin correctly sees nothing
-- here either way, matching its zero-farm-data-visibility rule.
create policy "view batches"
on public.batch for select
using (
  (public.current_role() in ('admin','manager') and business_id = public.current_business_id())
  or
  (public.current_role() = 'staff' and assigned_staff_id = public.current_account_id())
);

-- FIX: previously allowed 'super_admin' and 'admin' as well as
-- 'manager'. Only Manager registers batches — Admin's visibility
-- is read-only by design, and Super Admin never touches farm data.
create policy "manager creates batches"
on public.batch for insert
with check (
  public.current_role() = 'manager'
  and business_id = public.current_business_id()
);

create policy "manager updates batches"
on public.batch for update
using (
  public.current_role() = 'manager'
  and business_id = public.current_business_id()
)
with check (
  public.current_role() = 'manager'
  and business_id = public.current_business_id()
);

-- ---------- entry tables (mortality, feed, weight, vaccination, harvest) ----------
-- Append-only by design: entries are never edited or deleted once
-- submitted, a correction is a new entry instead (Staff cannot
-- self-edit at all; only Manager corrects, which in V1 means
-- guiding Staff to log a follow-up entry, not editing the old one).
--
-- Entry INSERT is open to two independent roles, one policy each:
-- "assigned staff logs X" lets Staff record on the batches assigned to
-- them, and "manager logs X" lets Manager record directly on any batch
-- in their own business. Postgres combines multiple permissive policies
-- on the same command with OR, so the two coexist rather than override
-- each other, and neither disturbs the other. This matches the mobile
-- UI, which shows a Manager the entry actions on any batch that has
-- nobody assigned to it. Admin and Super Admin still never touch field
-- data.
--
-- FIX applied to every SELECT below: previously scoped only by
-- business_id, letting Staff see every batch's entries, not just
-- their own.

create policy "view mortality"
on public.mortality_entry for select
using (
  batch_id in (
    select batch_id from public.batch
    where (public.current_role() in ('admin','manager') and business_id = public.current_business_id())
       or (public.current_role() = 'staff' and assigned_staff_id = public.current_account_id())
  )
);

create policy "assigned staff logs mortality"
on public.mortality_entry for insert
with check (
  recorded_by = public.current_account_id()
  and public.current_role() = 'staff'
  and batch_id in (select batch_id from public.batch where assigned_staff_id = public.current_account_id())
);

create policy "manager logs mortality"
on public.mortality_entry for insert
with check (
  recorded_by = public.current_account_id()
  and public.current_role() = 'manager'
  and batch_id in (select batch_id from public.batch where business_id = public.current_business_id())
);

create policy "view feed entries"
on public.feed_entry for select
using (
  batch_id in (
    select batch_id from public.batch
    where (public.current_role() in ('admin','manager') and business_id = public.current_business_id())
       or (public.current_role() = 'staff' and assigned_staff_id = public.current_account_id())
  )
);

create policy "assigned staff logs feed"
on public.feed_entry for insert
with check (
  recorded_by = public.current_account_id()
  and public.current_role() = 'staff'
  and batch_id in (select batch_id from public.batch where assigned_staff_id = public.current_account_id())
);

create policy "manager logs feed"
on public.feed_entry for insert
with check (
  recorded_by = public.current_account_id()
  and public.current_role() = 'manager'
  and batch_id in (select batch_id from public.batch where business_id = public.current_business_id())
);

create policy "view weight samples"
on public.weight_sample for select
using (
  batch_id in (
    select batch_id from public.batch
    where (public.current_role() in ('admin','manager') and business_id = public.current_business_id())
       or (public.current_role() = 'staff' and assigned_staff_id = public.current_account_id())
  )
);

create policy "assigned staff logs weight"
on public.weight_sample for insert
with check (
  recorded_by = public.current_account_id()
  and public.current_role() = 'staff'
  and batch_id in (select batch_id from public.batch where assigned_staff_id = public.current_account_id())
);

create policy "manager logs weight"
on public.weight_sample for insert
with check (
  recorded_by = public.current_account_id()
  and public.current_role() = 'manager'
  and batch_id in (select batch_id from public.batch where business_id = public.current_business_id())
);

create policy "view vaccinations"
on public.vaccination_entry for select
using (
  batch_id in (
    select batch_id from public.batch
    where (public.current_role() in ('admin','manager') and business_id = public.current_business_id())
       or (public.current_role() = 'staff' and assigned_staff_id = public.current_account_id())
  )
);

create policy "assigned staff logs vaccinations"
on public.vaccination_entry for insert
with check (
  recorded_by = public.current_account_id()
  and public.current_role() = 'staff'
  and batch_id in (select batch_id from public.batch where assigned_staff_id = public.current_account_id())
);

create policy "manager logs vaccinations"
on public.vaccination_entry for insert
with check (
  recorded_by = public.current_account_id()
  and public.current_role() = 'manager'
  and batch_id in (select batch_id from public.batch where business_id = public.current_business_id())
);

create policy "view harvest entries"
on public.harvest_entry for select
using (
  batch_id in (
    select batch_id from public.batch
    where (public.current_role() in ('admin','manager') and business_id = public.current_business_id())
       or (public.current_role() = 'staff' and assigned_staff_id = public.current_account_id())
  )
);

create policy "assigned staff logs harvest"
on public.harvest_entry for insert
with check (
  recorded_by = public.current_account_id()
  and public.current_role() = 'staff'
  and batch_id in (select batch_id from public.batch where assigned_staff_id = public.current_account_id())
);

create policy "manager logs harvest"
on public.harvest_entry for insert
with check (
  recorded_by = public.current_account_id()
  and public.current_role() = 'manager'
  and batch_id in (select batch_id from public.batch where business_id = public.current_business_id())
);

-- ---------- expense ----------
-- FIX: previously visible to anyone in the business with no role
-- check, and insertable by admin/super_admin/manager alike. Only
-- Manager ever touches money, and Staff has no visibility into
-- cost or pricing at all, by design — not even for their own batch.

create policy "view expenses"
on public.expense for select
using (
  public.current_role() in ('admin','manager')
  and batch_id in (select batch_id from public.batch where business_id = public.current_business_id())
);

create policy "manager logs expenses"
on public.expense for insert
with check (
  recorded_by = public.current_account_id()
  and public.current_role() = 'manager'
  and batch_id in (select batch_id from public.batch where business_id = public.current_business_id())
);

-- ---------- sale ----------
-- Same reasoning as expense: financial data, Manager-only, never
-- visible to Staff.

create policy "view sales"
on public.sale for select
using (
  public.current_role() in ('admin','manager')
  and harvest_id in (
    select harvest_id from public.harvest_entry
    where batch_id in (select batch_id from public.batch where business_id = public.current_business_id())
  )
);

create policy "manager records sales"
on public.sale for insert
with check (
  recorded_by = public.current_account_id()
  and public.current_role() = 'manager'
  and harvest_id in (
    select harvest_id from public.harvest_entry
    where batch_id in (select batch_id from public.batch where business_id = public.current_business_id())
  )
);

-- ============================================================
-- 7. TABLE-LEVEL GRANTS
-- RLS policies above only filter *which rows* a role can touch;
-- Postgres checks table-level privileges first, independently of
-- RLS, and neither this file nor Supabase's SQL Editor grants them
-- automatically. Without this section, every policy above is
-- unreachable — every query fails at the privilege check before
-- RLS is ever evaluated.
-- ============================================================

GRANT SELECT, INSERT, UPDATE ON public.account TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.business TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.batch TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.expense TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.feed_entry TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.harvest_entry TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.mortality_entry TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.sale TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.vaccination_entry TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.weight_sample TO authenticated;


create policy "super admin views businesses of its admins"
on public.business for select
using (
  public.current_role() = 'super_admin'
  and business_id in (
    select business_id from public.account
    where role = 'admin' and business_id is not null
  )
);

-- ============================================================
-- FIX: link_auth_user() stamps auth_user_id on first OTP login
-- but never touched status, so a Pending account stayed Pending
-- forever even after a real, successful first login — the
-- documented "First login (OTP verified)" → Active transition
-- in the account state diagram was never implemented anywhere.
-- This adds that one missing transition to the existing trigger.
-- Only flips pending -> active; an 'inactive' account is left
-- alone, so logging in does not silently undo a deliberate
-- deactivation.
-- ============================================================

create or replace function public.link_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.account
  set auth_user_id = new.id,
      status = case when status = 'pending' then 'active' else status end
  where lower(email) = lower(new.email)
    and auth_user_id is null;
  return new;
end;
$$;

-- No change needed to the trigger declaration itself — it already
-- points at this function by name, so replacing the function body
-- in place is enough:
--   create trigger on_auth_user_created
--   after insert on auth.users
--   for each row execute function public.link_auth_user();


-- ============================================================
-- MANUAL BACKFILL (one-time, run after the fix above)
-- The trigger only fires on a NEW row in auth.users — i.e. a
-- brand-new first login. Any account that already completed OTP
-- login *before* this fix was deployed has auth_user_id set but
-- is stuck on status = 'pending', because the old trigger never
-- flipped it and won't fire again for that same login. This
-- sweeps every such already-stuck row in one pass.
--
-- Safe by construction: only touches rows that are BOTH still
-- 'pending' AND already have a linked auth_user_id (i.e. proven
-- to have actually completed a first login) — an account that's
-- genuinely still pending (never logged in) has auth_user_id
-- null and will not match this WHERE clause.
-- ============================================================

update public.account
set status = 'active'
where status = 'pending'
  and auth_user_id is not null;

-- To limit this to one specific account instead of sweeping all
-- of them, add this line to the WHERE clause above:
--   and email = 'the-managers-email@example.com'


-- ============================================================
-- FIX: deactivating (or leaving) an account in a non-active
-- status only ever changed the `status` label — nothing actually
-- stopped that account from reading or writing data, because
-- every RLS policy in this schema is built on these three helper
-- functions, and none of them checked status. An 'inactive'
-- account with an already-authenticated session (or a 'pending'
-- one, defensively) could pass every policy exactly as if it
-- were active.
--
-- Adding "and status = 'active'" here is a single point of
-- control: these three functions feed every policy in the file,
-- so a non-active account now gets NULL from all three, and NULL
-- fails every policy comparison (role = 'admin', business_id =
-- current_business_id(), etc. all evaluate to NULL, not TRUE).
-- This revokes access everywhere at once, without needing to
-- touch each individual policy.
--
-- register_business() is unaffected: it reads auth_user_id =
-- auth.uid() directly, not through these helpers, and by the
-- time an Admin can call it they've already completed first
-- login, which the link_auth_user trigger flips to 'active' in
-- the same atomic update that sets auth_user_id — so there's no
-- window where a legitimately-logging-in user is blocked by this.
-- ============================================================

create or replace function public.current_account_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select account_id from public.account
  where auth_user_id = auth.uid() and status = 'active';
$$;

create or replace function public.current_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from public.account
  where auth_user_id = auth.uid() and status = 'active';
$$;

create or replace function public.current_business_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select business_id from public.account
  where auth_user_id = auth.uid() and status = 'active';
$$;

-- ============================================================
-- Lets the unauthenticated login screen check an account's
-- status by email BEFORE requesting an OTP, so a deactivated
-- account gets told plainly instead of burning an OTP send.
-- Must be SECURITY DEFINER + granted to anon: there is no
-- session yet at this point in the flow, so current_role() and
-- friends (which now require status = 'active' to resolve at
-- all, per the RLS access-revocation fix) can't be used here —
-- this function intentionally bypasses RLS to answer one
-- narrow question (status by email) before auth exists.
--
-- Known tradeoff, accepted for this stage of the project: this
-- does let a caller probe which emails exist in the system
-- (returns null for an unknown email, a status string for a
-- known one) — a mild email-enumeration surface. Worth
-- revisiting if this app moves past academic use.
-- ============================================================

create or replace function public.check_account_login_status(p_email text)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select status from public.account where lower(email) = lower(p_email) limit 1;
$$;

grant execute on function public.check_account_login_status(text) to anon, authenticated;


-- ============================================================
-- BUSINESS-LEVEL CASCADE: when an Admin is deactivated, every
-- Manager/Staff of that business loses all access immediately —
-- without their own `status` column ever being touched. Access
-- returns automatically the moment the Admin is reactivated,
-- since this check is live/derived, not a stored flag.
--
-- Admin and Super Admin are exempt from this extra check: Admin
-- IS the thing being checked (an Admin's own deactivation is
-- governed purely by their own status, same as before), and
-- Super Admin has no business at all.
-- ============================================================

create or replace function public.current_account_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select a.account_id
  from public.account a
  where a.auth_user_id = auth.uid()
    and a.status = 'active'
    and (
      a.role in ('super_admin', 'admin')
      or exists (
        select 1 from public.account admin_acct
        where admin_acct.business_id = a.business_id
          and admin_acct.role = 'admin'
          and admin_acct.status = 'active'
      )
    );
$$;

create or replace function public.current_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select a.role
  from public.account a
  where a.auth_user_id = auth.uid()
    and a.status = 'active'
    and (
      a.role in ('super_admin', 'admin')
      or exists (
        select 1 from public.account admin_acct
        where admin_acct.business_id = a.business_id
          and admin_acct.role = 'admin'
          and admin_acct.status = 'active'
      )
    );
$$;

create or replace function public.current_business_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select a.business_id
  from public.account a
  where a.auth_user_id = auth.uid()
    and a.status = 'active'
    and (
      a.role in ('super_admin', 'admin')
      or exists (
        select 1 from public.account admin_acct
        where admin_acct.business_id = a.business_id
          and admin_acct.role = 'admin'
          and admin_acct.status = 'active'
      )
    );
$$;

-- ============================================================
-- Extend the login pre-check so a Manager/Staff of a currently-
-- deactivated business can't even request an OTP — matching
-- "cannot use any of our resources, Supabase or any OTP or
-- auth." Returns 'inactive' (the existing block signal the app
-- already handles) when EITHER the account's own status is
-- inactive, OR it's Manager/Staff and their business currently
-- has no active Admin. Never writes to the stored status column
-- — this is a derived answer for gating only.
-- ============================================================

create or replace function public.check_account_login_status(p_email text)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select
    case
      when a.role in ('manager', 'staff')
        and a.status != 'inactive'
        and not exists (
          select 1 from public.account admin_acct
          where admin_acct.business_id = a.business_id
            and admin_acct.role = 'admin'
            and admin_acct.status = 'active'
        )
      then 'inactive'
      else a.status
    end
  from public.account a
  where lower(a.email) = lower(p_email)
  limit 1;
$$;

-- ============================================================
-- Returns the role stored for an email, or null when no account
-- exists. Lets the login screen refuse an OTP when the account
-- belongs to the other app (web: super_admin and admin, mobile:
-- manager and staff). Same accepted tradeoff as
-- check_account_login_status: a caller can learn whether an
-- email exists.
-- ============================================================


create or replace function public.check_account_login_role(p_email text)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from public.account where lower(email) = lower(p_email) limit 1;
$$;


grant execute on function public.check_account_login_role(text) to anon, authenticated;

-- ============================================================
-- New: lets an already-signed-in client periodically check "is
-- my session still valid right now," without re-running the
-- whole login flow. Feeds the force-logout polling timer.
-- ============================================================

create or replace function public.session_is_active()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.current_account_id() is not null;
$$;

grant execute on function public.session_is_active() to authenticated;