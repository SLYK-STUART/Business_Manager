import '../../../core/network/api_client.dart';

class AuthRepository {
  final ApiClient client;
  AuthRepository(this.client);

  Future<Map<String, dynamic>> login(String phone, String password) async {
    final response = await client.dio.post("/auth/login/", data: {
      "phone": phone,
      "password": password,
    });
    await client.saveTokens(response.data["access"], response.data["refresh"]);
    return response.data;
  }

  Future<Map<String, dynamic>> me() async {
    final response = await client.dio.get("/auth/me/");
    return response.data;
  }
}