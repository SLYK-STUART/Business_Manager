import 'package:dio/dio.dart';

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

  Future<List<int>> downloadPdf(String fileUrl) async {
    final response = await client.dio.get<List<int>>(
      fileUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data!;
  }

  Future<List<dynamic>> getCategoryRevenue(String start, String end) async {
    final response = await client.dio.get("/reports/category-revenue/", queryParameters: {"start": start, "end": end});
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> getSalesOverTime(String start, String end) async {
    final response = await client.dio.get("/reports/sales-over-time/", queryParameters: {"start": start, "end": end});
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getLoansSummary(String start, String end) async {
    final response = await client.dio.get("/reports/loans-summary/", queryParameters: {"start": start, "end": end});
    return response.data;
  }

  Future<Map<String, dynamic>> getCashReconciliation(String start, String end, {String module = "bar"}) async {
    final response = await client.dio.get("/reports/cash-reconciliation/", queryParameters: {"start": start, "end": end, "module": module});
    return response.data;
  }

  Future<Map<String, dynamic>> getGiveawaysSummary(String start, String end) async {
    final response = await client.dio.get("/reports/giveaways-summary/", queryParameters: {"start": start, "end": end});
    return response.data;
  }
}