import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api/api_service.dart';
import '../core/storage/token_storage.dart';
import '../core/storage/role_storage.dart';
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
  bool isUploading = false;
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

  /* ===============================
     📸 IMAGE OPTIONS BOTTOM SHEET
  =============================== */
  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text("Take Photo"),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text("Choose from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              if (user?["profileImage"] != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    "Remove Photo",
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfileImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  /* ===============================
     📤 UPLOAD IMAGE
  =============================== */
  Future<void> _pickAndUploadImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);

    if (pickedFile == null) return;

    setState(() => isUploading = true);

    final response = await ApiService.multipart(
      "/users/upload-profile-photo",
      {},
      file: File(pickedFile.path),
      fileFieldName: "image",
    );

    setState(() => isUploading = false);

    if (response != null && response["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile photo updated successfully"),
          backgroundColor: Colors.green,
        ),
      );
      _loadProfile();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to upload profile photo"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /* ===============================
     🗑 REMOVE IMAGE
  =============================== */
  Future<void> _removeProfileImage() async {
    setState(() => isUploading = true);

    final response = await ApiService.post("/users/remove-profile-photo", {});

    setState(() => isUploading = false);

    if (response != null && response["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile photo removed successfully"),
          backgroundColor: Colors.green,
        ),
      );
      _loadProfile();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to remove profile photo"),
          backgroundColor: Colors.red,
        ),
      );
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

  Future<void> _navigateAndRefresh(String route) async {
    await Navigator.pushNamed(context, route);
    _loadProfile();
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

    Navigator.pushNamedAndRemoveUntil(
      context,
      "/login",
      (route) => false,
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
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
              ? const Center(child: Text("Unable to load profile"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 24),
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
    );
  }

  Widget _buildProfileHeader() {
    return Container(
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
          GestureDetector(
            onTap: _showImageOptions,
            child: Stack(
              clipBehavior: Clip.none, // 🔥 VERY IMPORTANT
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: user!["profileImage"] != null
                      ? NetworkImage(
                          user!["profileImage"] +
                              "?t=${DateTime.now().millisecondsSinceEpoch}",
                        )
                      : null,
                  child: user!["profileImage"] == null
                      ? const Icon(Icons.person,
                          size: 50, color: AppColors.primary)
                      : null,
                ),
                if (isUploading)
                  const Positioned.fill(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _infoTile("Status", user!["status"], Icons.info_outline),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _actionTile(
                "Change Email",
                Icons.email_outlined,
                () => _navigateAndRefresh("/change-email"),
              ),
              const Divider(height: 1),
              _actionTile(
                "Change Phone Number",
                Icons.phone_android_outlined,
                () => _navigateAndRefresh("/change-mobile"),
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
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _confirmLogout,
        child: const Text("Logout"),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _actionTile(
                  "Call Support", Icons.call, () => openLink(supportPhone)),
              const Divider(height: 1),
              _actionTile("WhatsApp Support", Icons.chat_bubble_outline,
                  () => openLink(supportWhatsApp)),
              const Divider(height: 1),
              _actionTile(
                  "Email Support", Icons.email, () => openLink(supportEmail)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _infoTile(String label, String? value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      trailing: Text(value ?? "-"),
    );
  }

  Widget _actionTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
