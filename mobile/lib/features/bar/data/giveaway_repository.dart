import '../../../core/network/api_client.dart';

class GiveawayRepository {
  final ApiClient client;
  GiveawayRepository(this.client);

  Future<void> createGiveaway(String itemId, String recipientName) async {
    await client.dio.post("/bar/giveaways/", data: {"item": itemId, "recipient_name": recipientName});
  }
}