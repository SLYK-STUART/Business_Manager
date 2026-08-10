import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../data/item_repository.dart';

final itemRepositoryProvider = Provider((ref) => ItemRepository(ref.watch(apiClientProvider)));

final itemListProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(itemRepositoryProvider);
  return repo.getItems();
});