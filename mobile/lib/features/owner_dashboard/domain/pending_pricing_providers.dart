import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../data/pending_pricing_repository.dart';

final pendingPricingRepositoryProvider = Provider((ref) => PendingPricingRepository(ref.watch(apiClientProvider)));

final pendingPricingListProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(pendingPricingRepositoryProvider).list();
});