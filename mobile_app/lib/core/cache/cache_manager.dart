import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheManager {

  static Future<void> save(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();

    final payload = {
      "data": data,
      "timestamp": DateTime.now().millisecondsSinceEpoch
    };

    await prefs.setString(key, jsonEncode(payload));
  }

  static Future<dynamic> get(String key, int maxAgeSeconds) async {
    final prefs = await SharedPreferences.getInstance();

    final cached = prefs.getString(key);

    if (cached == null) return null;

    final decoded = jsonDecode(cached);

    final timestamp = decoded["timestamp"];
    final now = DateTime.now().millisecondsSinceEpoch;

    final age = (now - timestamp) / 1000;

    if (age > maxAgeSeconds) {
      return null;
    }

    return decoded["data"];
  }

  static Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}