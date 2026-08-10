import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_provider.dart';
import '../data/notifications_repository.dart';

final notificationsRepositoryProvider = Provider((ref) => NotificationsRepository(ref.watch(apiClientProvider)));

final notificationsListProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(notificationsRepositoryProvider).list();
});