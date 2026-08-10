import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../../features/auth/data/auth_repository.dart';
import '../notifications/fcm_service.dart';

final apiClientProvider = Provider((ref) => ApiClient());

final authRepositoryProvider = Provider(
      (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

final currentUserProvider = FutureProvider((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return repo.me();
});

final fcmServiceProvider = Provider((ref) => FcmService(ref.watch(apiClientProvider)));