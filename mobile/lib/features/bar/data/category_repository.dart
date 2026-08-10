import '../../../core/network/api_client.dart';

class CategoryRepository {
  final ApiClient client;
  CategoryRepository(this.client);

  Future<List<dynamic>> getCategories() async {
    final response = await client.dio.get("/bar/categories/");
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createCategory(String name) async {
    final response = await client.dio.post("/bar/categories/", data: {"name": name});
    return response.data;
  }
}