import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

class ApiService {

  /// =====================================================
  /// 🌐 INTERNET CHECK
  /// =====================================================
  static Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// =====================================================
  /// 🔁 REFRESH ACCESS TOKEN
  /// =====================================================
  static Future<bool> refreshToken() async {
    try {
      final refreshToken = await TokenStorage.getRefreshToken();

      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + "/auth/refresh-token"),
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
    } catch (_) {
      return false;
    }
  }

  /// =====================================================
  /// ================= CACHE HELPERS =================
  /// =====================================================

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

  static Future<dynamic> _getCache(String key,
      {int maxAgeSeconds = 60}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(key);

      if (cached == null) return null;

      final decoded = jsonDecode(cached);

      if (decoded["timestamp"] == null || decoded["data"] == null) {
        await prefs.remove(key);
        return null;
      }

      final timestamp = decoded["timestamp"] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      final ageSeconds = (now - timestamp) / 1000;

      if (ageSeconds > maxAgeSeconds) {
        await prefs.remove(key);
        return null;
      }

      return decoded["data"];
    } catch (e) {
      debugPrint("CACHE READ ERROR ($key): $e");
      return null;
    }
  }

  /// =====================================================
  /// ================= POST =================
  /// =====================================================
  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {

    if (!await hasInternet()) {
      return {"error": true, "message": "No internet connection"};
    }

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

    return jsonDecode(response.body);
  }

  /// =====================================================
  /// ================= GET =================
  /// =====================================================
  static Future<dynamic> get(String endpoint) async {

    final cacheKey = "CACHE_$endpoint";

    try {

      if (!await hasInternet()) {
        final cachedData = await _getCache(cacheKey);
        if (cachedData != null) return cachedData;

        return {"error": true, "message": "No internet connection"};
      }

      final token = await TokenStorage.getToken();

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

      final data = jsonDecode(response.body);

      await _saveCache(cacheKey, data);

      return data;

    } catch (e) {

      debugPrint("GET ERROR => $e");

      final cachedData = await _getCache(cacheKey);

      if (cachedData != null) {
        return cachedData;
      }

      return {"error": true, "message": "Network error"};
    }
  }

  /// =====================================================
  /// ================= PUT =================
  /// =====================================================
  static Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {

    if (!await hasInternet()) {
      return {"error": true, "message": "No internet connection"};
    }

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

    return jsonDecode(response.body);
  }

  /// =====================================================
  /// ================= PATCH =================
  /// =====================================================
  static Future<dynamic> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {

    if (!await hasInternet()) {
      return {"error": true, "message": "No internet connection"};
    }

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

    return jsonDecode(response.body);
  }

  /// =====================================================
  /// ================= MULTIPART =================
  /// =====================================================
  static Future<dynamic> multipart(
    String endpoint,
    Map<String, dynamic> fields, {
    List<XFile>? xFiles,
    required String fileFieldName,
  }) async {

    if (!await hasInternet()) {
      return {"error": true, "message": "No internet connection"};
    }

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

      if (response.body.isEmpty) {
        return {"error": true, "message": "Empty server response"};
      }

      return jsonDecode(response.body);

    } catch (e) {
      debugPrint("MULTIPART ERROR => $e");
      return {"error": true, "message": "Network error"};
    }
  }

  /// =====================================================
  /// ================= DELETE =================
  /// =====================================================
  static Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {

    if (!await hasInternet()) {
      return {"error": true, "message": "No internet connection"};
    }

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

    if (response.body.isEmpty) {
      return {"error": true, "message": "Empty server response"};
    }

    return jsonDecode(response.body);
  }

}