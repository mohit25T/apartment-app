import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class CacheService {
  /// Save JSON-compatible data to SharedPreferences
  static Future<void> saveData(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(data);
      await prefs.setString(key, jsonString);
    } catch (e) {
      debugPrint("CacheService Save Error [$key]: $e");
    }
  }

  /// Retrieve and decode JSON data from SharedPreferences
  static Future<dynamic> getData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(key);
      if (jsonString != null) {
        return jsonDecode(jsonString);
      }
    } catch (e) {
      debugPrint("CacheService Get Error [$key]: $e");
    }
    return null;
  }

  /// Remove data for a specific key
  static Future<void> clearData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
