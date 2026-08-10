import '../network/api_client.dart';

class LockRepository {
  final ApiClient client;
  LockRepository(this.client);

  Future<void> setPasscode(String passcode) async {
    await client.dio.post("/auth/passcode/set/", data: {"passcode": passcode});
  }

  Future<bool> verifyPasscode(String passcode) async {
    try {
      await client.dio.post("/auth/passcode/verify/", data: {"passcode": passcode});
      return true;
    } catch (_) {
      return false;
    }
  }
}