import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../data/loan_repository.dart';

final loanRepositoryProvider = Provider((ref) => LoanRepository(ref.watch(apiClientProvider)));

final loanListProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(loanRepositoryProvider).getLoans();
});