import 'package:shared_preferences/shared_preferences.dart';

class UserStorage {
  static const String _keyUserId = "user_id";   // ✅ NEW
  static const String _keyName = "user_name";
  static const String _keyEmail = "user_email";
  static const String _keyMobile = "user_mobile";

  static Future<void> saveUser({
    String? userId,   // ✅ NEW
    String? name,
    String? email,
    String? mobile,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (userId != null) await prefs.setString(_keyUserId, userId);
    if (name != null) await prefs.setString(_keyName, name);
    if (email != null) await prefs.setString(_keyEmail, email);
    if (mobile != null) await prefs.setString(_keyMobile, mobile);
  }

  // ✅ NEW METHOD
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);  // ✅ clear userId also
    await prefs.remove(_keyName);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyMobile);
  }
}
