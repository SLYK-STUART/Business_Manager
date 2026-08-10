import '../../../core/network/api_client.dart';

class SaleRepository {
  final ApiClient client;
  SaleRepository(this.client);

  Future<Map<String, dynamic>> createSale(List<Map<String, dynamic>> lineItems) async {
    final response = await client.dio.post("/bar/sales/", data: {"line_items": lineItems});
    return response.data;
  }
}