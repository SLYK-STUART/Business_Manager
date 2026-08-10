import '../../../core/network/api_client.dart';

class CashCollectionRepository {
  final ApiClient client;
  CashCollectionRepository(this.client);

  Future<Map<String, dynamic>> getSummary(String module) async {
    final response = await client.dio.get("/bar/cash-collections/summary/", queryParameters: {"module": module});
    return response.data;
  }

  Future<Map<String, dynamic>> collect(double amount, bool leaveRemainder, String module) async {
    final response = await client.dio.post("/bar/cash-collections/", data: {
      "collected_amount": amount,
      "leave_remainder": leaveRemainder,
      "module": module,
    });
    return response.data;
  }
}