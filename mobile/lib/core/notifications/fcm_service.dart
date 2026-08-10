import 'package:firebase_messaging/firebase_messaging.dart';
import '../network/api_client.dart';

class FcmService {
  final ApiClient client;
  FcmService(this.client);

  Future<void> registerToken() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    final token = await messaging.getToken();
    if (token != null) {
      await client.dio.post("/auth/fcm-token/", data: {"fcm_token": token});
    }
    // Keep the backend in sync if the token ever rotates
    messaging.onTokenRefresh.listen((newToken) async {
      await client.dio.post("/auth/fcm-token/", data: {"fcm_token": newToken});
    });
  }
}