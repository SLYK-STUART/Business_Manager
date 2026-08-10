import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/auth/auth_provider.dart';
import '../data/approvals_repository.dart';

final approvalsRepositoryProvider = Provider((ref) => ApprovalsRepository(ref.watch(apiClientProvider)));

final approvalsStatusFilterProvider = StateProvider<String>((ref) => "pending");

final approvalsListProvider = FutureProvider.autoDispose((ref) async {
  final status = ref.watch(approvalsStatusFilterProvider);
  return ref.watch(approvalsRepositoryProvider).list(status: status);
});