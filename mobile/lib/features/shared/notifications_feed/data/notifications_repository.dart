import '../../../../core/network/api_client.dart';

class NotificationsRepository {
  final ApiClient client;
  NotificationsRepository(this.client);

  Future<List<dynamic>> list() async {
    final response = await client.dio.get("/notifications/");
    return response.data as List<dynamic>;
  }

  Future<void> dismiss(String id) async {
    await client.dio.post("/notifications/$id/dismiss/");
  }
}