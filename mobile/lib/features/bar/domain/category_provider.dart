import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../data/category_repository.dart';

final categoryRepositoryProvider = Provider((ref) => CategoryRepository(ref.watch(apiClientProvider)));

final categoryListProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(categoryRepositoryProvider).getCategories();
});