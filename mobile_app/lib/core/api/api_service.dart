import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

class ApiService {
  // =====================================================
  // 🔁 REFRESH ACCESS TOKEN
  // =====================================================
  static Future<bool> refreshToken() async {
    try {
      final refreshToken = await TokenStorage.getRefreshToken();

      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + "/api/auth/refresh-token"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "refreshToken": refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        await TokenStorage.saveToken(data["token"]);

        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // =====================================================
  // ================= CACHE HELPERS =================
  // =====================================================

  static Future<void> _saveCache(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final payload = {
        "data": data,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      };

      await prefs.setString(key, jsonEncode(payload));
    } catch (e) {
      debugPrint("CACHE SAVE ERROR ($key): $e");
    }
  }

  static Future<dynamic> _getCache(String key, {int maxAgeSeconds = 60}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final cached = prefs.getString(key);

      if (cached == null) return null;

      final decoded = jsonDecode(cached);

      // Validate structure
      if (decoded == null ||
          decoded["timestamp"] == null ||
          decoded["data"] == null) {
        await prefs.remove(key);
        return null;
      }

      final timestamp = decoded["timestamp"] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      final ageSeconds = (now - timestamp) / 1000;

      if (ageSeconds > maxAgeSeconds) {
        // Cache expired
        await prefs.remove(key);
        return null;
      }

      return decoded["data"];
    } catch (e) {
      debugPrint("CACHE READ ERROR ($key): $e");
      return null;
    }
  }

  // =====================================================
  // ================= POST =================
  // =====================================================
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

    if (response.statusCode == 401) {
      final refreshed = await refreshToken();
      if (refreshed) {
        return post(endpoint, body);
      }
    }

    print("STATUS CODE => ${response.statusCode}");
    print("RAW RESPONSE => ${response.body}");

    return jsonDecode(response.body);
  }

  // =====================================================
  // ================= GET =================
  // =====================================================
  static Future<dynamic> get(String endpoint) async {
    try {
      final token = await TokenStorage.getToken();

      final cacheKey = "CACHE_$endpoint";

      // Try cache first
      final cachedData = await _getCache(cacheKey);

      if (cachedData != null) {
        print("CACHE HIT => $endpoint");
      }

      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + endpoint),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 401) {
        final refreshed = await refreshToken();
        if (refreshed) {
          return get(endpoint);
        }
      }

      print("STATUS CODE => ${response.statusCode}");
      print("RAW RESPONSE => ${response.body}");

      if (!response.headers["content-type"]!.contains("application/json")) {
        return {"error": true, "message": "Invalid server response"};
      }

      final data = jsonDecode(response.body);

      // Save fresh response to cache
      await _saveCache(cacheKey, data);

      return data;
    } catch (e) {
      print("GET ERROR => $e");

      // If network fails return cached data
      final cacheKey = "CACHE_$endpoint";
      final cachedData = await _getCache(cacheKey);

      if (cachedData != null) {
        print("RETURNING CACHED DATA");
        return cachedData;
      }

      return {"error": true, "message": "Network error"};
    }
  }

  // =====================================================
  // ================= PUT =================
  // =====================================================
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

    if (response.statusCode == 401) {
      final refreshed = await refreshToken();
      if (refreshed) {
        return put(endpoint, body);
      }
    }

    print("STATUS CODE => ${response.statusCode}");
    print("RAW RESPONSE => ${response.body}");

    return jsonDecode(response.body);
  }

  // =====================================================
  // ================= PATCH =================
  // =====================================================
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

      if (response.statusCode == 401) {
        final refreshed = await refreshToken();
        if (refreshed) {
          return patch(endpoint, body: body);
        }
      }

      print("STATUS CODE => ${response.statusCode}");
      print("RAW RESPONSE => ${response.body}");

      if (!response.headers["content-type"]!.contains("application/json")) {
        return {"error": true, "message": "Invalid server response"};
      }

      return jsonDecode(response.body);
    } catch (e) {
      return {"error": true, "message": "Network error"};
    }
  }

  // =====================================================
  // ================= MULTIPART =================
  // =====================================================
  static Future<dynamic> multipart(
    String endpoint,
    Map<String, dynamic> fields, {
    List<XFile>? xFiles,
    required String fileFieldName,
  }) async {
    try {
      final token = await TokenStorage.getToken();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.baseUrl + endpoint),
      );

      if (token != null) {
        request.headers["Authorization"] = "Bearer $token";
      }

      fields.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      if (xFiles != null && xFiles.isNotEmpty) {
        for (var file in xFiles) {
          if (kIsWeb) {
            final bytes = await file.readAsBytes();

            request.files.add(
              http.MultipartFile.fromBytes(
                fileFieldName,
                bytes,
                filename: file.name,
                contentType: MediaType('image', 'jpeg'),
              ),
            );
          } else {
            request.files.add(
              await http.MultipartFile.fromPath(
                fileFieldName,
                file.path,
                contentType: MediaType('image', 'jpeg'),
              ),
            );
          }
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 401) {
        final refreshed = await refreshToken();
        if (refreshed) {
          return multipart(endpoint, fields,
              xFiles: xFiles, fileFieldName: fileFieldName);
        }
      }

      print("STATUS CODE => ${response.statusCode}");
      print("RAW RESPONSE => ${response.body}");

      if (response.body.isEmpty) {
        return {"error": true, "message": "Empty server response"};
      }

      return jsonDecode(response.body);
    } catch (e) {
      print("MULTIPART ERROR => $e");

      return {"error": true, "message": "Network error"};
    }
  }

  // =====================================================
  // ================= DELETE =================
  // =====================================================
  static Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final token = await TokenStorage.getToken();

      final response = await http.delete(
        Uri.parse(ApiConstants.baseUrl + endpoint),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: body != null ? jsonEncode(body) : null,
      );

      if (response.statusCode == 401) {
        final refreshed = await refreshToken();
        if (refreshed) {
          return delete(endpoint, body: body);
        }
      }

      print("STATUS CODE => ${response.statusCode}");
      print("RAW RESPONSE => ${response.body}");

      if (response.body.isEmpty) {
        return {"error": true, "message": "Empty server response"};
      }

      if (!response.headers["content-type"]!.contains("application/json")) {
        return {"error": true, "message": "Invalid server response"};
      }

      return jsonDecode(response.body);
    } catch (e) {
      return {"error": true, "message": "Network error"};
    }
  }
}
