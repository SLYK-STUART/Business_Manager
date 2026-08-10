import '../../../core/network/api_client.dart';

class ApprovalsRepository {
  final ApiClient client;
  ApprovalsRepository(this.client);

  Future<List<dynamic>> list({String status = "pending"}) async {
    final response = await client.dio.get("/approvals/", queryParameters: {"status": status});
    return response.data as List<dynamic>;
  }

  Future<void> approve(String id) async {
    await client.dio.post("/approvals/$id/approve/");
  }

  Future<void> reject(String id) async {
    await client.dio.post("/approvals/$id/reject/");
  }
}