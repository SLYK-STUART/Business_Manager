import '../../../core/network/api_client.dart';

class ReportsRepository {
  final ApiClient client;
  ReportsRepository(this.client);

  Future<Map<String, dynamic>> getProfitReport(String start, String end) async {
    final response = await client.dio.get("/reports/profit/", queryParameters: {"start": start, "end": end});
    return response.data;
  }

  Future<Map<String, dynamic>> getTrends(String start, String end) async {
    final response = await client.dio.get("/reports/trends/", queryParameters: {"start": start, "end": end});
    return response.data;
  }

  Future<String> exportPdf(String start, String end) async {
    final response = await client.dio.get("/reports/export/pdf/", queryParameters: {"start": start, "end": end});
    return response.data["file_url"];
  }

  Future<Map<String, dynamic>> getRoomReport(String start, String end, {int revenueLimit = 5}) async {
    final response = await client.dio.get("/reports/rooms/", queryParameters: {"start": start, "end": end, "revenue_limit": revenueLimit});
    return response.data;
  }
}