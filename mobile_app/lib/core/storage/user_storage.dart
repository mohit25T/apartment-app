import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserStorage {
  static const String _keyUserId = "user_id";
  static const String _keyName = "user_name";
  static const String _keyEmail = "user_email";
  static const String _keyMobile = "user_mobile";

  // 🔥 NEW (Full user cache)
  static const String _keyUserFull = "user_full_profile";

  /* =====================================================
     SAVE BASIC USER DATA (EXISTING LOGIC - NOT CHANGED)
  ===================================================== */

  static Future<void> saveUser({
    String? userId,
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

  /* =====================================================
     SAVE FULL PROFILE (NEW)
  ===================================================== */

  static Future<void> saveFullUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_keyUserFull, jsonEncode(user));

    // also update basic fields
    await saveUser(
      userId: user["_id"],
      name: user["name"],
      email: user["email"],
      mobile: user["mobile"],
    );
  }

  /* =====================================================
     GET FULL PROFILE (NEW)
  ===================================================== */

  static Future<Map<String, dynamic>?> getFullUser() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString(_keyUserFull);

    if (data == null) return null;

    return jsonDecode(data);
  }

  /* =====================================================
     EXISTING METHODS
  ===================================================== */

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  static Future<String?> getMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyMobile);
  }

  /* =====================================================
     CLEAR USER
  ===================================================== */

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_keyUserId);
    await prefs.remove(_keyName);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyMobile);

    // 🔥 also clear full profile cache
    await prefs.remove(_keyUserFull);
  }
}
