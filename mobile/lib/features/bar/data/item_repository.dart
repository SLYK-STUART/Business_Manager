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

  Future<void> updateItem(String itemId, {required String name, required double sellingPrice, required int lowStockThreshold}) async {
    await client.dio.patch("/bar/items/$itemId/", data: {
      "name": name,
      "selling_price": sellingPrice,
      "low_stock_threshold": lowStockThreshold,
    });
  }
}
