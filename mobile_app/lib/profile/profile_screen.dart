import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_service.dart';
import '../core/storage/token_storage.dart';
import '../core/storage/role_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = true;
  Map<String, dynamic>? user;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    NotificationService.requestPermission();
    NotificationService.getFcmToken();
  }

  Future<void> _loadProfile() async {
    setState(() => isLoading = true);

    final response = await ApiService.get("/users/profile");

    if (response != null && response["success"] == true) {
      setState(() {
        user = response["user"];
        isLoading = false;
      });
    } else {
      setState(() {
        user = null;
        isLoading = false;
      });
    }
  }

  final String supportPhone = "tel:+917043622519";
  final String supportWhatsApp =
      "whatsapp://send?phone=917043622519&text=Hi%2C%20I%27m%20facing%20an%20issue%20with%20my%20account.";
  final String supportEmail = "mailto:mohittopiya2564@gmail.com";

  Future<void> openLink(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to open support option")),
      );
    }
  }

  /// 🔁 Navigate & refresh on return
  Future<void> _navigateAndRefresh(String route) async {
    await Navigator.pushNamed(context, route);
    _loadProfile();
  }

  /// 🔥 LOGOUT (CLEAR SESSION PROPERLY)
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear login flags
    await prefs.remove('isLoggedIn');
    await prefs.remove('role');
    await prefs.remove('admin_mode');

    // Clear token & roles
    await TokenStorage.clearToken();
    await RoleStorage.clearRoles();

    // Redirect to login
    Navigator.pushNamedAndRemoveUntil(
      context,
      "/login",
      (route) => false,
    );
  }

  /// ✅ LOGOUT CONFIRMATION
  void _confirmLogout() {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(context); // close dialog
              _logout(); // perform logout
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? const Center(child: Text("Unable to load profile"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // ===== PROFILE HEADER =====
                      Center(
                        child: Column(
                          children: [
                            const CircleAvatar(
                              radius: 45,
                              child: Icon(Icons.person, size: 45),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              user!["name"] ?? "",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(user!["email"] ?? ""),
                            const SizedBox(height: 2),
                            Text(user!["mobile"] ?? ""),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ===== BASIC DETAILS =====
                      Card(
                        child: Column(
                          children: [
                            _infoTile("Email", user!["email"]),
                            _infoTile("Mobile", user!["mobile"]),
                            _infoTile("Status", user!["status"]),
                            if (user!["flatNo"] != null)
                              _infoTile("Flat No", user!["flatNo"]),
                            if (user!["society"] != null)
                              _infoTile(
                                "Society",
                                user!["society"]["name"],
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ===== ACCOUNT ACTIONS =====
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.email),
                              title: const Text("Change Email"),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
                              onTap: () => _navigateAndRefresh("/change-email"),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.phone),
                              title: const Text("Change Phone Number"),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
                              onTap: () =>
                                  _navigateAndRefresh("/change-mobile"),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ===== LOGOUT =====
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: _confirmLogout,
                          child: const Text("Logout"),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ===== SUPPORT =====
                      Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                "Support",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.call),
                              title: const Text("Call Support"),
                              onTap: () => openLink(supportPhone),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.chat),
                              title: const Text("WhatsApp Support"),
                              onTap: () => openLink(supportWhatsApp),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.email),
                              title: const Text("Email Support"),
                              onTap: () => openLink(supportEmail),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _infoTile(String label, String? value) {
    return ListTile(
      title: Text(label),
      trailing: Text(
        value ?? "-",
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }
}
