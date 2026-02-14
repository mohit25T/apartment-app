import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

class ApiService {
  // ================= POST =================
  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await TokenStorage.getToken();

    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + endpoint),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    print("STATUS CODE => ${response.statusCode}");
    print("RAW RESPONSE => ${response.body}");

    return jsonDecode(response.body);
  }

  // ================= GET =================
  static Future<dynamic> get(String endpoint) async {
    try {
      final token = await TokenStorage.getToken();

      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + endpoint),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      print("STATUS CODE => ${response.statusCode}");
      print("RAW RESPONSE => ${response.body}");

      // 🔐 safety check
      if (!response.headers["content-type"]!.contains("application/json")) {
        return {"error": true, "message": "Invalid server response"};
      }

      return jsonDecode(response.body);
    } catch (e) {
      return {"error": true, "message": "Network error"};
    }
  }

  // ================= PUT =================
  static Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await TokenStorage.getToken();

    final response = await http.put(
      Uri.parse(ApiConstants.baseUrl + endpoint),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    print("STATUS CODE => ${response.statusCode}");
    print("RAW RESPONSE => ${response.body}");

    return jsonDecode(response.body);
  }

  // ================= PATCH =================
  static Future<dynamic> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final token = await TokenStorage.getToken();

      final response = await http.patch(
        Uri.parse(ApiConstants.baseUrl + endpoint),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: body != null ? jsonEncode(body) : null,
      );

      print("STATUS CODE => ${response.statusCode}");
      print("RAW RESPONSE => ${response.body}");

      // 🔐 safety check
      if (!response.headers["content-type"]!.contains("application/json")) {
        return {"error": true, "message": "Invalid server response"};
      }

      return jsonDecode(response.body);
    } catch (e) {
      return {"error": true, "message": "Network error"};
    }
  }
}
