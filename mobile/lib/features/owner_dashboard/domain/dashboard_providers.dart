import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/auth/auth_provider.dart';
import '../data/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider((ref) => DashboardRepository(ref.watch(apiClientProvider)));

final dashboardProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(dashboardRepositoryProvider).getDashboard();
});

final selectedModuleProvider = StateProvider<String>((ref) => "bar");