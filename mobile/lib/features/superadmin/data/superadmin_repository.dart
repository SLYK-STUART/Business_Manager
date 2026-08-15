import '../../../core/network/api_client.dart';

class SuperadminRepository {
  final ApiClient client;
  SuperadminRepository(this.client);

  Future<List<dynamic>> getBusinesses() async {
    final response = await client.dio.get("/platform/businesses/");
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getBusiness(String id) async {
    final response = await client.dio.get("/platform/businesses/$id/");
    return response.data;
  }

  Future<Map<String, dynamic>> createBusiness(String name, String address, List<String> modules) async {
    final response = await client.dio.post("/platform/businesses/", data: {
      "name": name,
      "address": address,
      "modules": modules.map((m) => {"module_type": m}).toList(),
    });
    return response.data;
  }

  Future<void> createOwner(String businessId, String name, String phone, String password) async {
    await client.dio.post("/platform/businesses/$businessId/create-owner/", data: {
      "name": name, "phone": phone, "password": password,
    });
  }

  Future<void> toggleActive(String businessId) async {
    await client.dio.post("/platform/businesses/$businessId/toggle-active/");
  }

  Future<void> toggleModule(String businessId, String moduleType) async {
    await client.dio.post("/platform/businesses/$businessId/toggle-module/", data: {"module_type": moduleType});
  }
}