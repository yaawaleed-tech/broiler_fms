import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/data/local/database.dart';

/// The single shared Drift database instance, used by every local
/// repository. Mobile only.
///
/// This file, and anything that imports it, must never be reachable
/// from the web build's import graph. `database.dart` itself imports
/// `dart:io`, which does not exist on web, so pulling this provider
/// into any file the web entry point can reach would break that build.
final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());