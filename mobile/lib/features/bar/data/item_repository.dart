import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

class ItemRepository {
  final ApiClient client;
  ItemRepository(this.client);

  Future<List<dynamic>> getItems() async {
    final response = await client.dio.get("/bar/items/");
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> restock(String itemId, {required String mode, required int quantity, double? unitPrice, double? totalPrice}) async {
    final body = {
      "mode": mode,
      "quantity": quantity,
      if (unitPrice != null) "unit_price": unitPrice,
      if (totalPrice != null) "total_price": totalPrice,
    };
    final response = await client.dio.post("/bar/items/$itemId/restock/", data: body);
    return response.data;
  }

  Future<void> createItem({
    required String name,
    required double buyingPrice,
    required double sellingPrice,
    required int currentStock,
    required int lowStockThreshold,
    String? photoPath,
    String? categoryId,
  }) async {
    final formData = FormData.fromMap({
      "name": name,
      "buying_price": buyingPrice,
      "selling_price": sellingPrice,
      "current_stock": currentStock,
      "low_stock_threshold": lowStockThreshold,
      if (categoryId != null) "category": categoryId,
      if (photoPath != null) "photo": await MultipartFile.fromFile(photoPath),
    });
    await client.dio.post("/bar/items/", data: formData);
  }

  Future<Map<String, dynamic>> getItemDetail(String itemId) async {
    final response = await client.dio.get("/bar/items/$itemId/detail_full/");
    return response.data;
  }

  Future<void> updateItemPhoto(String itemId, String photoPath) async {
    final formData = FormData.fromMap({
      "photo": await MultipartFile.fromFile(photoPath),
    });
    await client.dio.patch("/bar/items/$itemId/", data: formData);
  }

  Future<void> updateItem(
      String itemId, {
        String? name,
        double? sellingPrice,
        int? lowStockThreshold,
        String? categoryId,
        bool clearCategory = false,
      }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (sellingPrice != null) data['selling_price'] = sellingPrice;
    if (lowStockThreshold != null) data['low_stock_threshold'] = lowStockThreshold;
    if (clearCategory) {
      data['category'] = null;
    } else if (categoryId != null) {
      data['category'] = categoryId;
    }

    await client.dio.patch("/bar/items/$itemId/", data: data);
  }
}
