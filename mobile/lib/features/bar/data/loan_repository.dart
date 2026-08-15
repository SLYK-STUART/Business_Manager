import '../../../core/network/api_client.dart';

class LoanRepository {
  final ApiClient client;
  LoanRepository(this.client);

  Future<List<dynamic>> getCustomers() async {
    final response = await client.dio.get("/bar/customers/");
    return response.data as List<dynamic>;
  }

  Future<bool> checkPhoneDuplicate(String phone) async {
    final response = await client.dio.get("/bar/customers/check-phone/", queryParameters: {"phone": phone});
    return response.data["duplicate"] == true;
  }

  Future<Map<String, dynamic>> createCustomer(String name, String? phone) async {
    final response = await client.dio.post("/bar/customers/", data: {"name": name, "phone": phone ?? ""});
    return response.data;
  }

  Future<List<dynamic>> getLoans() async {
    final response = await client.dio.get("/bar/loans/");
    return response.data as List<dynamic>;
  }

  Future<void> repayLoan(String loanId, double amount) async {
    await client.dio.post("/bar/loans/$loanId/repay/", data: {"amount": amount});
  }

  Future<void> writeOffLoan(String loanId) async {
    await client.dio.post("/bar/loans/$loanId/manage/", data: {"action": "write_off"});
  }

  Future<void> rescheduleLoan(String loanId, String newDueDate) async {
    await client.dio.post("/bar/loans/$loanId/manage/", data: {"action": "reschedule", "new_due_date": newDueDate});
  }
}