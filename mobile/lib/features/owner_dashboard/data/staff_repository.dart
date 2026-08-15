import '../../../core/network/api_client.dart';

class StaffRepository {
  final ApiClient client;
  StaffRepository(this.client);

  Future<List<dynamic>> getStaff() async {
    final response = await client.dio.get("/auth/staff/");
    return response.data as List<dynamic>;
  }

  Future<void> createStaff(
      String name,
      String phone,
      String password,
      List<String> roles,
      ) async {
    await client.dio.post("/auth/staff/", data: {
      "name": name,
      "phone": phone,
      "password": password,
      "roles": roles,
    });
  }

  Future<void> updateStaff(
      String staffId, {
        List<String>? roles,
        bool? isActive,
      }) async {
    final data = <String, dynamic>{};
    if (roles != null) data['roles'] = roles;
    if (isActive != null) data['is_active'] = isActive;
    await client.dio.patch("/auth/staff/$staffId/", data: data);
  }
}