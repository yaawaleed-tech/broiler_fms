import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

// ============================================================
// Local Storage — the Drift database itself.
//
// This is the one and only place Repository is allowed to talk
// to. Domain never sees this file at all, it only ever calls
// Repository, which calls this. Sync Engine is the only other
// thing that touches this database directly, reading whatever's
// queued and writing down whatever comes back from Supabase.
// ============================================================

@DriftDatabase(
  tables: [
    Businesses,
    Accounts,
    Batches,
    Expenses,
    MortalityEntries,
    FeedEntries,
    WeightSamples,
    VaccinationEntries,
    HarvestEntries,
    Sales,
    SyncQueue,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Lets tests point the same schema at an in-memory database,
  /// instead of the on-disk file the app itself opens.
  AppDatabase.forTesting(super.executor);

  // Bump this whenever a table definition changes after the app is
  // already in real use, and extend the onUpgrade strategy below.
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          // Additive only: SyncQueue gains a rejected flag. New
          // installs get the column straight from createAll(), which
          // the default onCreate runs.
          if (from < 3) {
            await m.addColumn(syncQueue, syncQueue.rejected);
          }
        },
      );
}

LazyDatabase _openConnection() {
  // Deferred so the database file isn't touched until the first
  // real query, keeping app startup fast.
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'broiler_fms.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
