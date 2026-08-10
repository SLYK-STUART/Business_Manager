import '../../../../core/network/api_client.dart';

class ActivityLogRepository {
  final ApiClient client;
  ActivityLogRepository(this.client);

  Future<Map<String, dynamic>> list({String? cursor, String? module}) async {
    final response = await client.dio.get("/activity-log/", queryParameters: {
      if (cursor != null) "cursor": cursor,
      if (module != null) "module": module,
    });
    return response.data;
  }
}