import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart' show open;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/data/local/database.dart' show AppDatabase;
import 'package:broiler_fms/data/local/database_provider.dart';
import 'package:broiler_fms/data/remote/supabase_provider.dart';
import 'package:broiler_fms/domain/models/batch.dart';
import 'package:broiler_fms/domain/models/expense.dart';
import 'package:broiler_fms/domain/models/feed.dart';
import 'package:broiler_fms/domain/models/harvest.dart';
import 'package:broiler_fms/domain/models/mortality.dart';
import 'package:broiler_fms/domain/models/sale.dart';
import 'package:broiler_fms/domain/models/vaccination.dart';
import 'package:broiler_fms/domain/models/weight_sample.dart';
import 'package:broiler_fms/repository/batch/remote_batch_repository.dart';
import 'package:broiler_fms/repository/expense/remote_expense_repository.dart';
import 'package:broiler_fms/repository/feed/remote_feed_repository.dart';
import 'package:broiler_fms/repository/harvest/remote_harvest_repository.dart';
import 'package:broiler_fms/repository/mortality/remote_mortality_repository.dart';
import 'package:broiler_fms/repository/sale/remote_sale_repository.dart';
import 'package:broiler_fms/repository/vaccination/remote_vaccination_repository.dart';
import 'package:broiler_fms/repository/weight/remote_weight_repository.dart';
import 'package:broiler_fms/domain/batch/batch_domain.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/domain/current_account_domain.dart';
import 'package:broiler_fms/sync/pull_service.dart';
import 'package:broiler_fms/sync/sync_providers.dart';

/// Empty remotes: the point is that the Domains resolve and report, never
/// that anything comes back. These keep the pull off the network entirely.
class _StubBatchRemote extends RemoteBatchRepository {
  _StubBatchRemote(super.client);

  @override
  Future<List<Batch>> getAll() async => const [];
}

class _StubExpenseRemote extends RemoteExpenseRepository {
  _StubExpenseRemote(super.client);

  @override
  Future<List<Expense>> getAll() async => const [];
}

class _StubMortalityRemote extends RemoteMortalityRepository {
  _StubMortalityRemote(super.client);

  @override
  Future<List<Mortality>> getAll() async => const [];
}

class _StubFeedRemote extends RemoteFeedRepository {
  _StubFeedRemote(super.client);

  @override
  Future<List<Feed>> getAll() async => const [];
}

class _StubWeightRemote extends RemoteWeightRepository {
  _StubWeightRemote(super.client);

  @override
  Future<List<WeightSample>> getAll() async => const [];
}

class _StubVaccinationRemote extends RemoteVaccinationRepository {
  _StubVaccinationRemote(super.client);

  @override
  Future<List<Vaccination>> getAll() async => const [];
}

class _StubHarvestRemote extends RemoteHarvestRepository {
  _StubHarvestRemote(super.client);

  @override
  Future<List<Harvest>> getAll() async => const [];
}

class _StubSaleRemote extends RemoteSaleRepository {
  _StubSaleRemote(super.client);

  @override
  Future<List<Sale>> getAll() async => const [];
}

/// A container whose remotes never touch the network. Passing [account]
/// signs that account in; omitting it leaves the device signed out.
ProviderContainer _container(
  SupabaseClient client,
  AppDatabase db, {
  Account? account,
  bool signedOut = false,
}) {
  return ProviderContainer(
    overrides: [
      // The real one opens the on-disk database through path_provider,
      // which does not exist in a unit test.
      appDatabaseProvider.overrideWithValue(db),
      supabaseClientProvider.overrideWithValue(client),
      remoteBatchRepositoryProvider.overrideWithValue(_StubBatchRemote(client)),
      remoteExpenseRepositoryProvider
          .overrideWithValue(_StubExpenseRemote(client)),
      remoteMortalityRepositoryProvider
          .overrideWithValue(_StubMortalityRemote(client)),
      remoteFeedRepositoryProvider.overrideWithValue(_StubFeedRemote(client)),
      remoteWeightRepositoryProvider
          .overrideWithValue(_StubWeightRemote(client)),
      remoteVaccinationRepositoryProvider
          .overrideWithValue(_StubVaccinationRemote(client)),
      remoteHarvestRepositoryProvider
          .overrideWithValue(_StubHarvestRemote(client)),
      remoteSaleRepositoryProvider.overrideWithValue(_StubSaleRemote(client)),
      if (account != null || signedOut)
        currentAccountProvider.overrideWith((ref) async => account),
    ],
  );
}

DynamicLibrary _openSqlite() {
  try {
    return DynamicLibrary.open('libsqlite3.so');
  } on ArgumentError {
    return DynamicLibrary.open('libsqlite3.so.0');
  }
}

/// Regression cover for the cold-start crash.
///
/// pullServiceProvider is read by the app's root widget on every launch,
/// signed in or not, so building it must not need a signed-in account.
/// Every Domain behind it is bound to one, which is exactly what used to
/// throw during startup.
void main() {
  // The Domains reach path_provider and similar, which need a binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  if (Platform.isLinux) {
    open.overrideForAll(_openSqlite);
  }

  late AppDatabase db;
  late SupabaseClient client;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    client = SupabaseClient('https://example.supabase.co', 'anon-key');
    addTearDown(client.dispose);
    container = _container(client, db);
    addTearDown(container.dispose);
  });

  tearDown(() => db.close());

  Account staff() => Account(
        accountId: 'acc-staff',
        businessId: 'biz-1',
        role: 'staff',
        name: 'Sam',
        email: 'sam@example.com',
        status: 'active',
        createdAt: DateTime(2026, 1, 1),
      );

  /// A container with an account, already resolved. currentAccountProvider
  /// is a FutureProvider, so .value is null while it is still loading —
  /// exactly as in the app, nothing pulls until it has settled.
  Future<ProviderContainer> signedIn() async {
    final signedInContainer = _container(client, db, account: staff());
    addTearDown(signedInContainer.dispose);
    await signedInContainer.read(currentAccountProvider.future);
    return signedInContainer;
  }

  group('reading pullServiceProvider while signed out', () {
    test('does not throw', () {
      expect(() => container.read(pullServiceProvider), returnsNormally,
          reason: 'this is read at app start, before login');
    });

    test('reads the same instance twice', () {
      final first = container.read(pullServiceProvider);
      final second = container.read(pullServiceProvider);
      expect(identical(first, second), isTrue);
    });

    test('leaves the account error itself intact', () async {
      // The fix must not teach anything to swallow this. batchDomain is
      // still the right place for it, so it is still raised there.
      container = _container(client, db, signedOut: true);
      addTearDown(container.dispose);

      expect(container.read(pullServiceProvider), isNotNull,
          reason: 'the PullService itself builds fine');
      expect(
        () => container.read(batchDomainProvider),
        throwsA(isA<Exception>()),
        reason: 'but the domain still refuses without an account',
      );
    });
  });

  group('pulling after sign-in', () {
    test('resolves the domains and reports every table', () async {
      final signed = await signedIn();

      final result = await signed.read(pullServiceProvider).pullAll();

      // Nothing is cached locally, so every table comes back with no
      // updates and no error — which proves all eight Domains resolved.
      expect(result.errors, isEmpty);
      expect(result.tablesPulled, 8);
      expect(result.updated, 0);
    });

    test('pullAll still returns rather than throwing', () async {
      final signed = await signedIn();
      await expectLater(signed.read(pullServiceProvider).pullAll(), completes);
    });

    test('a pull while signed out reports the failure, not a crash',
        () async {
      // The PullService builds either way. If it is run with no account,
      // the Domain error is caught per table like any other, so the pull
      // reports rather than propagating.
      final result = await container.read(pullServiceProvider).pullAll();
      expect(result.errors, isNotEmpty);
    });
  });

  group('the real startup chain, signed out', () {
    test('building autoPullTriggerProvider does not throw', () {
      // The exact chain from the crash report: the app's root widget
      // builds AutoPullHost, whose initState reads this provider, whose
      // body watches pullServiceProvider. All of it runs on a cold start,
      // signed out.
      expect(
        () => container.read(autoPullTriggerProvider),
        returnsNormally,
        reason: 'nothing here may need a signed-in account',
      );
    });

    test('the trigger can be started and disposed while signed out', () {
      final trigger = container.read(autoPullTriggerProvider);
      expect(trigger.onChangesArrived, isNull);
      // start() registers a lifecycle observer and a connectivity listener
      // — neither of which may need an account.
      expect(trigger.start, returnsNormally);
      expect(trigger.dispose, returnsNormally);
    });
  });

  group('the in-flight guard', () {
    test('isPulling is false before a run and true during it', () async {
      final signed = await signedIn();

      final pull = signed.read(pullServiceProvider);
      expect(pull.isPulling, isFalse);

      final first = pull.pullAll();
      expect(pull.isPulling, isTrue);
      await first;
      expect(pull.isPulling, isFalse);
    });
  });
}