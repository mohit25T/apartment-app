import 'dart:convert';
import 'dart:io';
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

  // ================= MULTIPART (IMAGE UPLOAD) =================
  static Future<dynamic> multipart(
    String endpoint,
    Map<String, dynamic> fields, {
    required File? file,
    required String fileFieldName,
  }) async {
    try {
      final token = await TokenStorage.getToken();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.baseUrl + endpoint),
      );

      // Add headers
      if (token != null) {
        request.headers["Authorization"] = "Bearer $token";
      }

      // Add text fields
      fields.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Add file
      if (file != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            fileFieldName,
            file.path,
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("STATUS CODE => ${response.statusCode}");
      print("RAW RESPONSE => ${response.body}");

      if (response.body.isEmpty) {
        return {"error": true, "message": "Empty response from server"};
      }

      return jsonDecode(response.body);
    } catch (e) {
      return {"error": true, "message": "Network error"};
    }
  }
}
