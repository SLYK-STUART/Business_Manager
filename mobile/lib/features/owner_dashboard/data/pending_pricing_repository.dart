import '../../../core/network/api_client.dart';

class PendingPricingRepository {
  final ApiClient client;
  PendingPricingRepository(this.client);

  Future<List<dynamic>> list() async {
    final response = await client.dio.get("/bar/pending-pricing/");
    return response.data as List<dynamic>;
  }

  Future<void> setPrice(String restockId, {required String mode, double? unitPrice, double? totalPrice}) async {
    await client.dio.post("/bar/pending-pricing/$restockId/set_price/", data: {
      "mode": mode,
      if (unitPrice != null) "unit_price": unitPrice,
      if (totalPrice != null) "total_price": totalPrice,
    });
  }
}