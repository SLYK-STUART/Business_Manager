import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../data/room_repository.dart';

final roomRepositoryProvider = Provider((ref) => RoomRepository(ref.watch(apiClientProvider)));

final roomListProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(roomRepositoryProvider).getRooms();
});