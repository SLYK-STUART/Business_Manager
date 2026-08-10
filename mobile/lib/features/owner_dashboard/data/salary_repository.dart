import '../../../core/network/api_client.dart';

class SalaryRepository {
  final ApiClient client;
  SalaryRepository(this.client);

  Future<List<dynamic>> getSalaries() async {
    final response = await client.dio.get("/bar/salaries/");
    return response.data as List<dynamic>;
  }

  Future<void> setSalary(String staffId, double amount) async {
    await client.dio.post("/bar/salaries/", data: {
      "staff": staffId,
      "amount": amount,
    });
  }

  Future<List<dynamic>> getStaff() async {
    final response = await client.dio.get("/auth/staff/");
    return response.data as List<dynamic>;
  }

  Future<void> paySalary(String salaryId, {double? amount}) async {
    await client.dio.post("/bar/salaries/$salaryId/pay/", data: amount != null ? {"amount": amount} : {});
  }
}