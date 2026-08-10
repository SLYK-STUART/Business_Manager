import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../data/staff_repository.dart';

final staffRepositoryProvider = Provider((ref) => StaffRepository(ref.watch(apiClientProvider)));

final staffManagementListProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(staffRepositoryProvider).getStaff();
});