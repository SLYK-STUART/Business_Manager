import '../../../core/network/api_client.dart';

class NbtRepository {
  final ApiClient client;
  NbtRepository(this.client);

  Future<void> create(String direction, double amount, String description) async {
    await client.dio.post("/bar/non-business-transactions/", data: {
      "direction": direction,
      "amount": amount,
      "description": description,
    });
  }

  Future<List<dynamic>> list() async {
    final response = await client.dio.get("/bar/non-business-transactions/");
    return response.data as List<dynamic>;
  }
}