import '../../../core/network/api_client.dart';

class GiveawayRepository {
  final ApiClient client;
  GiveawayRepository(this.client);

  Future<void> createGiveawayBatch(String recipientName, List<Map<String, dynamic>> lineItems) async {
    await client.dio.post("/bar/giveaways/", data: {
      "recipient_name": recipientName,
      "line_items": lineItems,
    });
  }
}