import 'package:drift/drift.dart';

// ============================================================
// Local Storage — Drift table definitions
// Mirrors the Postgres schema in schema_corrected.sql exactly,
// including its CHECK constraints, so validation happens
// identically whether the app is online or offline.
//
// One rule deliberately does NOT live here: mortality + harvested
// <= starting_bird_count. That rule needs to read other rows
// across two tables, which a single table's CHECK can't express.
// It belongs in the Domain layer instead — see the note at the
// bottom of this file.
//
// IDs are generated client-side as UUID strings (via the `uuid`
// package) at the moment an entry is created, the same ID is then
// used when the row eventually syncs to Supabase. This is what
// lets the app work fully offline without waiting on a server to
// hand back a real ID before local work can continue.
// ============================================================
@DataClassName('Business')
class Businesses extends Table {
  TextColumn get businessId => text()();
  TextColumn get name => text()();
  TextColumn get address => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get businessType => text().nullable()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {businessId};
}

@DataClassName('Account')
class Accounts extends Table {
  TextColumn get accountId => text()();
  // Nullable: Super Admin has none; a freshly-invited Admin has
  // none until they register their business. Same reasoning as
  // the Postgres fix.
  TextColumn get businessId =>
      text().nullable().references(Businesses, #businessId)();
  TextColumn get authUserId => text().nullable().unique()();
  TextColumn get role => text().customConstraint(
      "NOT NULL CHECK (role IN ('super_admin','admin','manager','staff'))")();
  TextColumn get name => text()();
  TextColumn get email => text().unique()();
  // FIX: customConstraint() replaces .withDefault() entirely rather
  // than adding to it, so DEFAULT 'pending' has to live inside this
  // string itself to actually take effect.
  TextColumn get status => text().customConstraint(
      "NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','active','inactive'))")();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {accountId};
}
@DataClassName('Batch')
class Batches extends Table {
  TextColumn get batchId => text()();
  TextColumn get businessId => text().references(Businesses, #businessId)();

  // FIX: two foreign keys on this table both point at Accounts, so
  // Drift's generated reverse-lookup name ("batchesRefs") clashed
  // between them. Naming each one explicitly resolves it.
  @ReferenceName("assignedBatches")
  TextColumn get assignedStaffId =>
      text().nullable().references(Accounts, #accountId)();
  @ReferenceName("closedBatches")
  TextColumn get closedBy =>
      text().nullable().references(Accounts, #accountId)();

  TextColumn get batchName => text()();
  TextColumn get breed => text().nullable()();
  TextColumn get description => text().nullable()();
  IntColumn get startingBirdCount => integer()
      .customConstraint('NOT NULL CHECK (starting_bird_count > 0)')();
  DateTimeColumn get startDate => dateTime()();
  BoolColumn get isClosed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get closedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {batchId};
}

class Expenses extends Table {
  TextColumn get expenseId => text()();
  TextColumn get batchId => text().references(Batches, #batchId)();
  TextColumn get recordedBy => text().references(Accounts, #accountId)();
  TextColumn get category => text().customConstraint(
      "NOT NULL CHECK (category IN ('chicks','feed','vet_medication','other'))")();
  DateTimeColumn get date => dateTime()();
  RealColumn get quantity => real().nullable()();
  RealColumn get unitPrice => real().nullable()();
  RealColumn get amount =>
      real().customConstraint('NOT NULL CHECK (amount > 0)')();
  TextColumn get feedType => text().nullable()();
  TextColumn get medicationName => text().nullable()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();
  // NOT NULL DEFAULT now(), matching the fix agreed on the server
  // schema — the client never sets this itself, it's stamped the
  // instant a row is written, whether that's here locally or when
  // it eventually lands on Supabase.
  DateTimeColumn get syncedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {expenseId};
}

class MortalityEntries extends Table {
  TextColumn get mortalityId => text()();
  TextColumn get batchId => text().references(Batches, #batchId)();
  TextColumn get recordedBy => text().references(Accounts, #accountId)();
  DateTimeColumn get date => dateTime()();
  // Never zero — the absence of an entry is what "zero" means.
  IntColumn get count =>
      integer().customConstraint('NOT NULL CHECK (count >= 1)')();
  TextColumn get description => text().nullable()();
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {mortalityId};
}

class FeedEntries extends Table {
  TextColumn get feedEntryId => text()();
  TextColumn get batchId => text().references(Batches, #batchId)();
  TextColumn get recordedBy => text().references(Accounts, #accountId)();
  DateTimeColumn get date => dateTime()();
  RealColumn get quantity =>
      real().customConstraint('NOT NULL CHECK (quantity > 0)')();
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {feedEntryId};
}

class WeightSamples extends Table {
  TextColumn get weightSampleId => text()();
  TextColumn get batchId => text().references(Batches, #batchId)();
  TextColumn get recordedBy => text().references(Accounts, #accountId)();
  DateTimeColumn get date => dateTime()();
  RealColumn get sampleWeight =>
      real().customConstraint('NOT NULL CHECK (sample_weight > 0)')();
  IntColumn get sampleCount =>
      integer().customConstraint('NOT NULL CHECK (sample_count > 0)')();
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {weightSampleId};
}

class VaccinationEntries extends Table {
  TextColumn get vaccinationId => text()();
  TextColumn get batchId => text().references(Batches, #batchId)();
  TextColumn get recordedBy => text().references(Accounts, #accountId)();
  DateTimeColumn get date => dateTime()();
  TextColumn get vaccineName => text()();
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {vaccinationId};
}

class HarvestEntries extends Table {
  TextColumn get harvestId => text()();
  TextColumn get batchId => text().references(Batches, #batchId)();
  TextColumn get recordedBy => text().references(Accounts, #accountId)();
  DateTimeColumn get date => dateTime()();
  IntColumn get birdCount =>
      integer().customConstraint('NOT NULL CHECK (bird_count > 0)')();
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {harvestId};
}

class Sales extends Table {
  TextColumn get saleId => text()();
  TextColumn get harvestId =>
      text().references(HarvestEntries, #harvestId)();
  TextColumn get recordedBy => text().references(Accounts, #accountId)();
  TextColumn get disposition => text().customConstraint(
      "NOT NULL CHECK (disposition IN ('sale','gift_cull'))")();
  TextColumn get buyerName => text().nullable()();
  // Stays nullable, deliberately — a gift_cull row genuinely has
  // no pricing method at all, that's a real state, not missing
  // data. Same reasoning as paymentStatus directly below.
  TextColumn get pricingMethod => text().nullable().customConstraint(
      "CHECK (pricing_method IN ('per_kg','flat_total')) NULL")();
  RealColumn get weightSold => real().nullable()();
  RealColumn get pricePerUnit => real().nullable()();
  RealColumn get amount =>
      real().customConstraint('NOT NULL CHECK (amount >= 0)')();
  TextColumn get paymentStatus => text().nullable().customConstraint(
      "CHECK (payment_status IN ('paid','pending')) NULL")();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<String> get customConstraints => [
    // Same composite rule as the Postgres sale_shape constraint:
    // a gift/cull row carries nothing but a zero amount; a sale
    // row always needs a payment status and a positive amount,
    // and per_kg specifically requires a real weight and price,
    // while flat_total forbids weight and treats price_per_unit
    // (price per bird) as the one genuinely optional field.
    '''CHECK (
          (disposition = 'gift_cull' AND pricing_method IS NULL
            AND weight_sold IS NULL AND price_per_unit IS NULL
            AND payment_status IS NULL AND amount = 0)
          OR
          (disposition = 'sale' AND payment_status IS NOT NULL AND amount > 0
            AND (
              (pricing_method = 'per_kg' AND weight_sold IS NOT NULL AND weight_sold > 0
                AND price_per_unit IS NOT NULL AND price_per_unit > 0)
              OR
              (pricing_method = 'flat_total' AND weight_sold IS NULL
                AND (price_per_unit IS NULL OR price_per_unit > 0))
            )
          )
        )''',
  ];

  @override
  Set<Column> get primaryKey => {saleId};
}

// ============================================================
// NOTE — deliberately not implemented here:
//
// "mortality + harvested <= starting_bird_count" must be enforced
// in the Domain layer, not as a table constraint, because it needs
// to sum rows from MortalityEntries and HarvestEntries together
// and compare that against a value on a third table, Batches. This
// is exactly the offline-sync gap identified earlier: the check
// must run the moment Staff types a number in, using whatever this
// device already has in local storage (synced or not), not wait
// for a round-trip to Supabase. Implement it as a function in
// domain/ that both the Record Mortality and Record Harvest flows
// call before ever writing to Repository.
// ============================================================