import '../../../core/network/api_client.dart';

class DashboardRepository {
  final ApiClient client;
  DashboardRepository(this.client);

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await client.dio.get("/reports/dashboard/");
    return response.data;
  }
}