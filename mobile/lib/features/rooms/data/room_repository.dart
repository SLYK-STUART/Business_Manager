import '../../../core/network/api_client.dart';

class RoomRepository {
  final ApiClient client;
  RoomRepository(this.client);

  Future<List<dynamic>> getRooms() async {
    final response = await client.dio.get("/rooms/rooms/");
    return response.data as List<dynamic>;
  }

  Future<void> createRoom(String name, String roomType, double nightlyRate) async {
    await client.dio.post("/rooms/rooms/", data: {
      "name": name,
      "room_type": roomType,
      "nightly_rate": nightlyRate,
    });
  }

  Future<void> updateRoom(String roomId, {required String name, required String roomType, required double nightlyRate}) async {
    await client.dio.patch("/rooms/rooms/$roomId/", data: {
      "name": name,
      "room_type": roomType,
      "nightly_rate": nightlyRate,
    });
  }

  Future<void> deactivateRoom(String roomId) async {
    await client.dio.delete("/rooms/rooms/$roomId/");
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