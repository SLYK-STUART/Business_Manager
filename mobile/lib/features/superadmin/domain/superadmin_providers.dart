import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../data/superadmin_repository.dart';

final superadminRepositoryProvider = Provider((ref) => SuperadminRepository(ref.watch(apiClientProvider)));

final businessListProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(superadminRepositoryProvider).getBusinesses();
});