import '../../../core/network/api_client.dart';

class RoomRepository {
  final ApiClient client;
  RoomRepository(this.client);

  Future<List<dynamic>> getRooms() async {
    final response = await client.dio.get("/rooms/rooms/");
    return response.data as List<dynamic>;
  }

  Future<void> createRoom(String name, double nightlyRate) async {
    await client.dio.post("/rooms/rooms/", data: {"name": name, "nightly_rate": nightlyRate});
  }

  Future<Map<String, dynamic>> checkin(String roomId, int nights, double discountAmount) async {
    final response = await client.dio.post("/rooms/bookings/", data: {
      "room_id": roomId,
      "nights": nights,
      "discount_amount": discountAmount,
    });
    return response.data;
  }

  Future<void> checkout(String bookingId) async {
    await client.dio.post("/rooms/bookings/$bookingId/checkout/");
  }

  Future<List<dynamic>> getBookings() async {
    final response = await client.dio.get("/rooms/bookings/");
    return response.data as List<dynamic>;
  }
}