import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_service.dart';
import '../core/storage/token_storage.dart';
import '../core/storage/role_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/storage/user_storage.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/walking_loader.dart';

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

  /// 🔥 LOGOUT (CLEAR SESSION + CLEAR FCM TOKEN)
  Future<void> _logout() async {
    try {
      await ApiService.post("/auth/logout", {});
    } catch (e) {
      debugPrint("⚠️ Logout API failed: $e");
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('isLoggedIn');
    await prefs.remove('role');
    await prefs.remove('admin_mode');

    // ✅ THIS WAS MISSING
    await UserStorage.clearUser();

    await TokenStorage.clearToken();
    await RoleStorage.clearRoles();

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
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: WalkingLoader(size: 60))
          : user == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text("Unable to load profile"),
                      TextButton(
                        onPressed: _loadProfile,
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // ===== PROFILE HEADER =====
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.1),
                              child: const Icon(Icons.person,
                                  size: 50, color: AppColors.primary),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              user!["name"] ?? "User Name",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user!["email"] ?? "-",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                user!["mobile"] ?? "-",
                                style: const TextStyle(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ===== BASIC DETAILS =====
                      _buildSectionTitle("Details"),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6),
                          ],
                        ),
                        child: Column(
                          children: [
                            _infoTile(
                                "Status", user!["status"], Icons.info_outline),
                            if (user!["flatNo"] != null)
                              _infoTile("Flat No", user!["flatNo"], Icons.home),
                            if (user!["society"] != null)
                              _infoTile(
                                "Society",
                                user!["society"]["name"],
                                Icons.location_city,
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ===== ACCOUNT ACTIONS =====
                      _buildSectionTitle("Account Settings"),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6),
                          ],
                        ),
                        child: Column(
                          children: [
                            _actionTile(
                              "Change Email",
                              Icons.email_outlined,
                              () => _navigateAndRefresh("/change-email"),
                            ),
                            const Divider(height: 1, indent: 20, endIndent: 20),
                            _actionTile(
                              "Change Phone Number",
                              Icons.phone_android_outlined,
                              () => _navigateAndRefresh("/change-mobile"),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ===== LOGOUT =====
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.error,
                            elevation: 0,
                            side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _confirmLogout,
                          child: const Text("Logout"),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ===== SUPPORT =====
                      _buildSectionTitle("Support"),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6),
                          ],
                        ),
                        child: Column(
                          children: [
                            _actionTile("Call Support", Icons.call,
                                () => openLink(supportPhone)),
                            const Divider(height: 1, indent: 20, endIndent: 20),
                            _actionTile(
                                "WhatsApp Support",
                                Icons.chat_bubble_outline,
                                () => openLink(supportWhatsApp)),
                            const Divider(height: 1, indent: 20, endIndent: 20),
                            _actionTile("Email Support", Icons.email,
                                () => openLink(supportEmail)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _infoTile(String label, String? value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 24),
      title: Text(label,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      trailing: Text(
        value ?? "-",
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textPrimary),
      ),
    );
  }

  Widget _actionTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 24),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
