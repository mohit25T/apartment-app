import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../core/api/api_service.dart';
import '../core/storage/token_storage.dart';
import '../core/storage/role_storage.dart';
import '../core/storage/user_storage.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_provider.dart';
import '../core/widgets/walking_loader.dart';
import '../core/services/update_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = true;
  bool isUploading = false;
  Map<String, dynamic>? user;
  String appVersion = "1.0.0";

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        appVersion = info.version;
      });
    }
  }

  Future<void> _loadProfile() async {
    setState(() => isLoading = true);

    Map<String, dynamic>? cachedUser = await UserStorage.getFullUser();
    if (cachedUser != null && mounted) {
      setState(() {
        user = cachedUser;
        isLoading = false;
      });
    }

    final response = await ApiService.get("/users/profile");

    if (response != null && response["success"] == true) {
      final freshUser = response["user"];

      final String cachedStr = jsonEncode(cachedUser ?? {});
      final String freshStr = jsonEncode(freshUser ?? {});

      if (cachedStr == freshStr) {
        if (mounted && isLoading) setState(() => isLoading = false);
        return; // No change, skip rebuild
      }

      await UserStorage.saveFullUser(freshUser);
      if (mounted) {
        setState(() {
          user = freshUser;
          isLoading = false;
        });
      }
    } else {
      if (cachedUser == null && mounted) {
        setState(() {
          user = null;
          isLoading = false;
        });
      }
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded,
                      color: AppColors.primary),
                  title: const Text("Take Photo",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded,
                      color: AppColors.primary),
                  title: const Text("Choose from Gallery",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.gallery);
                  },
                ),
                if (user?["profileImage"] != null)
                  ListTile(
                    leading:
                        const Icon(Icons.delete_rounded, color: Colors.red),
                    title: const Text(
                      "Remove Photo",
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _removeProfileImage();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: source, imageQuality: 70);

    if (pickedFile == null) return;

    setState(() => isUploading = true);
    final response = await ApiService.multipart(
      "/users/upload-profile-photo",
      {},
      xFiles: [pickedFile],
      fileFieldName: "image",
    );

    setState(() => isUploading = false);

    if (response != null && response["success"] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile photo updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _loadProfile();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(response?["message"] ?? "Failed to upload profile photo"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeProfileImage() async {
    setState(() => isUploading = true);
    final response = await ApiService.post("/users/remove-profile-photo", {});

    setState(() => isUploading = false);

    if (response != null && response["success"] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile photo removed successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _loadProfile();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to remove profile photo"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  final String supportPhone = "tel:+917043622519";
  final String supportWhatsApp =
      "whatsapp://send?phone=917043622519&text=Hi%2C%20I%27m%20facing%20an%20issue%20with%20my%20account.";
  final String supportEmail = "mailto:mohittopiya2564@gmail.com";

  Future<void> openLink(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to open support option")),
        );
      }
    }
  }

  Future<void> _navigateAndRefresh(String route) async {
    await Navigator.pushNamed(context, route);
    await _loadProfile();
  }

  Future<void> _logout() async {
    try {
      await ApiService.post("/auth/logout", {});
    } catch (e) {
      debugPrint("Logout API failed: $e");
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('role');
    await prefs.remove('admin_mode');

    await UserStorage.clearUser();
    await TokenStorage.clearToken();
    await RoleStorage.clearRoles();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        "/login",
        (route) => false,
      );
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Profile",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: isLoading
          ? const Center(child: WalkingLoader(size: 60))
          : user == null
              ? const Center(child: Text("Unable to load profile"))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildProfileHeader(),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            _buildDetailsSection(),
                            const SizedBox(height: 24),
                            _buildAccountSettings(),
                            const SizedBox(height: 30),
                            _buildLogoutButton(),
                            const SizedBox(height: 30),
                            _buildSupportSection(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 100, bottom: 40, left: 24, right: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFF1E88E5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _showImageOptions,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.white,
                    backgroundImage: user!["profileImage"] != null
                        ? NetworkImage(
                            user!["profileImage"] +
                                "?t=${DateTime.now().millisecondsSinceEpoch}",
                          )
                        : null,
                    child: user!["profileImage"] == null
                        ? const Icon(Icons.person,
                            size: 60, color: AppColors.primary)
                        : null,
                  ),
                ),
                if (isUploading)
                  const Positioned.fill(
                    child: Center(
                        child: CircularProgressIndicator(color: Colors.white)),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            user!["name"] ?? "User Name",
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user!["email"] ?? "-",
            style:
                TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user!["mobile"] ?? "-",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Details"),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _infoTile("Status", user!["status"], Icons.info_outline_rounded),
              if (user!["flatNo"] != null)
                _infoTile("Flat", "${user!["wing"] ?? ""}-${user!["flatNo"]}",
                    Icons.home_rounded),
              if (user!["society"] != null)
                _infoTile(
                  "Society",
                  user!["society"]["name"],
                  Icons.location_city_rounded,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Account Settings"),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildThemeToggleTile(),
              const Divider(height: 1),
              _actionTile(
                "Change Email",
                Icons.email_outlined,
                () => _navigateAndRefresh("/change-email"),
              ),
              _actionTile(
                "Change Phone Number",
                Icons.phone_android_outlined,
                () => _navigateAndRefresh("/change-mobile"),
              ),
              const Divider(height: 1),
              _actionTile(
                "Check for Updates",
                Icons.system_update_rounded,
                () => UpdateService().checkForUpdates(silent: false),
                subtitle: "v$appVersion",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).cardColor,
          foregroundColor: AppColors.error,
          surfaceTintColor: Theme.of(context).cardColor,
          shadowColor: AppColors.error.withOpacity(0.3),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.error.withOpacity(0.5)),
          ),
        ),
        onPressed: _confirmLogout,
        child: const Text("Logout",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSupportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Support"),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _actionTile(
                  "Call Support", Icons.call_rounded,
                  () => openLink(supportPhone),
                  iconColor: Colors.green),
              const Divider(height: 1),
              _actionTile("WhatsApp Support", Icons.chat_bubble_rounded,
                  () => openLink(supportWhatsApp),
                  iconColor: Colors.teal),
              const Divider(height: 1),
              _actionTile(
                  "Email Support", Icons.email_rounded,
                  () => openLink(supportEmail),
                  iconColor: Colors.blue),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).textTheme.displayLarge?.color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _infoTile(String label, String? value, IconData icon) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Text(
        value ?? "-",
        style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color),
      ),
    );
  }

  Widget _actionTile(String title, IconData icon, VoidCallback onTap,
      {Color? iconColor, String? subtitle}) {
    final finalIconColor = iconColor ?? AppColors.primary;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: finalIconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: finalIconColor, size: 24),
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: Colors.grey.withOpacity(0.6)),
      ),
      onTap: onTap,
    );
  }

  Widget _buildThemeToggleTile() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: const Text(
        "Dark Mode",
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.deepPurple.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          color: Colors.deepPurple,
          size: 24,
        ),
      ),
      value: isDark,
      activeColor: Colors.deepPurple,
      activeTrackColor: Colors.deepPurple.withOpacity(0.4),
      inactiveThumbColor: Colors.grey.shade400,
      inactiveTrackColor: Colors.grey.shade200,
      onChanged: (value) {
        themeProvider.toggleTheme(value);
      },
    );
  }
}
