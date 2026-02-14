import 'package:shared_preferences/shared_preferences.dart';

class RoleStorage {
  static Future<void> saveRoles(List roles) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
      "roles",
      roles.map((e) => e.toString()).toList(),
    );
  }

  static Future<List<String>> getRoles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList("roles") ?? [];
  }

  static Future<void> clearRoles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('roles');
  }
}
