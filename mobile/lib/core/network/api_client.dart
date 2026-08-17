import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final Dio dio;
  final _storage = const FlutterSecureStorage();

  ApiClient() : dio = Dio(BaseOptions(baseUrl: dotenv.env['API_BASE_URL'] ?? "http://192.168.1.113:8000/api")) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: "access_token");
        if (token != null) {
          options.headers["Authorization"] = "Bearer $token";
        }
        handler.next(options);
      },
    ));
  }

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: "access_token", value: access);
    await _storage.write(key: "refresh_token", value: refresh);
  }

  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }
}