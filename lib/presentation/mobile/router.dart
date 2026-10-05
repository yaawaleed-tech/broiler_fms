import 'package:broiler_fms/presentation/mobile/batch/register_batch_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:broiler_fms/domain/current_account_domain.dart';
import 'package:broiler_fms/presentation/mobile/batch/batch_detail_screen.dart';
import 'package:broiler_fms/presentation/mobile/entries/feed_form_screen.dart';
import 'package:broiler_fms/presentation/mobile/entries/harvest_form_screen.dart';
import 'package:broiler_fms/presentation/mobile/entries/mortality_form_screen.dart';
import 'package:broiler_fms/presentation/mobile/entries/vaccination_form_screen.dart';
import 'package:broiler_fms/presentation/mobile/entries/weight_form_screen.dart';
import 'package:broiler_fms/presentation/mobile/home/batch_list_screen.dart';
import 'package:broiler_fms/presentation/mobile/login/code_screen.dart';
import 'package:broiler_fms/presentation/mobile/login/email_screen.dart';

import 'package:broiler_fms/presentation/mobile/batch/assign_staff_screen.dart';
import 'package:broiler_fms/presentation/mobile/expense/expense_form_screen.dart';

import 'package:broiler_fms/presentation/mobile/sale/harvest_list_screen.dart';
import 'package:broiler_fms/presentation/mobile/sale/price_harvest_screen.dart';
import 'package:broiler_fms/presentation/mobile/financial/financial_summary_screen.dart';

/// Mobile's route tree. Staff and Manager share the same screens,
/// each screen decides internally what a given role sees, rather than
/// splitting into two separate trees.
final mobileRouterProvider = Provider<GoRouter>((ref) {
  Future<String?> redirect(BuildContext context, GoRouterState state) async {
    final account = await ref.read(currentAccountProvider.future);
    final isLoggingIn = state.matchedLocation.startsWith('/login');

    if (account == null && !isLoggingIn) return '/login';
    if (account != null && isLoggingIn) return '/';
    return null;
  }

  return GoRouter(
    initialLocation: '/',
    redirect: redirect,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const EmailScreen(),
      ),
      GoRoute(
        path: '/login/code',
        builder: (context, state) {
          final email = state.extra as String;
          return CodeScreen(email: email);
        },
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const BatchListScreen(),
      ),
      GoRoute(
        path: '/batches/:batchId',
        builder: (context, state) {
          final batchId = state.pathParameters['batchId']!;
          return BatchDetailScreen(batchId: batchId);
        },
      ),
      GoRoute(
        path: '/batches/:batchId/mortality',
        builder: (context, state) {
          final batchId = state.pathParameters['batchId']!;
          return MortalityFormScreen(batchId: batchId);
        },
      ),
      GoRoute(
        path: '/batches/:batchId/feed',
        builder: (context, state) {
          final batchId = state.pathParameters['batchId']!;
          return FeedFormScreen(batchId: batchId);
        },
      ),
      GoRoute(
        path: '/batches/:batchId/harvest',
        builder: (context, state) {
          final batchId = state.pathParameters['batchId']!;
          return HarvestFormScreen(batchId: batchId);
        },
      ),
      GoRoute(
        path: '/batches/:batchId/weight',
        builder: (context, state) {
          final batchId = state.pathParameters['batchId']!;
          return WeightFormScreen(batchId: batchId);
        },
      ),
      GoRoute(
        path: '/batches/:batchId/vaccination',
        builder: (context, state) {
          final batchId = state.pathParameters['batchId']!;
          return VaccinationFormScreen(batchId: batchId);
        },
      ),
      GoRoute(
        path: '/batches/:batchId/expense',
        builder: (context, state) {
          final batchId = state.pathParameters['batchId']!;
          return ExpenseFormScreen(batchId: batchId);
        },
      ),
      GoRoute(
        path: '/batches/:batchId/assign-staff',
        builder: (context, state) {
          final batchId = state.pathParameters['batchId']!;
          return AssignStaffScreen(batchId: batchId);
        },
      ),
      GoRoute(
        path: '/register-batch',
        builder: (context, state) => const RegisterBatchScreen(),
      ),
      GoRoute(
        path: '/batches/:batchId/harvests',
        builder: (context, state) {
          final batchId = state.pathParameters['batchId']!;
          return HarvestListScreen(batchId: batchId);
        },
      ),
      GoRoute(
        path: '/batches/:batchId/harvests/:harvestId/price',
        builder: (context, state) {
          final batchId = state.pathParameters['batchId']!;
          final harvestId = state.pathParameters['harvestId']!;
          return PriceHarvestScreen(batchId: batchId, harvestId: harvestId);
        },
      ),
      GoRoute(
        path: '/batches/:batchId/financial',
        builder: (context, state) {
          final batchId = state.pathParameters['batchId']!;
          return FinancialSummaryScreen(batchId: batchId);
        },
      ),
    ],
  );
});