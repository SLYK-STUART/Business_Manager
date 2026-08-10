import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../data/salary_repository.dart';

final salaryRepositoryProvider = Provider((ref) => SalaryRepository(ref.watch(apiClientProvider)));

final salaryListProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(salaryRepositoryProvider).getSalaries();
});

final staffListProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(salaryRepositoryProvider).getStaff();
});