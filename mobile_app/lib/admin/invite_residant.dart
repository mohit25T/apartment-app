import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/walking_loader.dart';

class InviteResidentScreen extends StatefulWidget {
  const InviteResidentScreen({super.key});

  @override
  State<InviteResidentScreen> createState() => _InviteResidentScreenState();
}

class _InviteResidentScreenState extends State<InviteResidentScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController flatController = TextEditingController();
  final TextEditingController wingController = TextEditingController();

  bool loading = false;

  // Admin can invite only OWNER
  String selectedRole = "OWNER";

  // ===============================
  // 🔥 INVITE FUNCTION (UPDATED)
  // ===============================
  Future<void> inviteResident() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        mobileController.text.length != 10 ||
        flatController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter name, email, mobile number and flat number"),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => loading = true);

    final response = await ApiService.post(
      "/invites/invite-resident",
      {
        "name": nameController.text.trim(),
        "email": emailController.text.trim().toLowerCase(),
        "mobile": mobileController.text.trim(),
        "wing": wingController.text.trim().toUpperCase(),
        "flatNo": flatController.text.trim(),
        "role": selectedRole,
      },
    );

    setState(() => loading = false);

    if (response != null && response["success"] == true) {
      final upgradeRequired = response["upgradeRequired"] == true;

      // ✅ Clear fields
      nameController.clear();
      emailController.clear();
      mobileController.clear();
      flatController.clear();
      wingController.clear();

      // ✅ Redirect back (Dashboard)
      Navigator.pop(context);

      // 🔥 Delay ensures dashboard loads before popup
      Future.delayed(const Duration(milliseconds: 400), () {
        if (upgradeRequired) {
          _showUpgradePopup();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response["message"] ?? "Invite sent successfully"),
              backgroundColor: Colors.green,
            ),
          );
        }
      });

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response?["message"] ?? "Something went wrong"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ===============================
  // 🔥 UPGRADE POPUP
  // ===============================
  void _showUpgradePopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.workspace_premium, color: Colors.orange),
              SizedBox(width: 10),
              Text("Upgrade Required"),
            ],
          ),
          content: const Text(
            "You have exceeded your flat limit.\n\nUpgrade your subscription to continue using all features.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Later"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/subscription");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text("Upgrade Now"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    flatController.dispose();
    wingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Invite Resident"),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Invite Flat Owner",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Admins can invite only flat owners. Owners can later add tenants.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            _buildTextField(nameController, "Full Name", Icons.person_outline),
            const SizedBox(height: 16),

            _buildTextField(
              emailController,
              "Email Address",
              Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              wingController,
              "Wing (A/B/C)",
              Icons.home_outlined,
              maxLength: 1,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              flatController,
              "Flat Number (e.g. 203)",
              Icons.home_outlined,
            ),

            _buildTextField(
              mobileController,
              "Mobile Number",
              Icons.phone_android_outlined,
              keyboardType: TextInputType.phone,
              maxLength: 10,
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : inviteResident,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        width: 40,
                        height: 40,
                        child: WalkingLoader(size: 40, color: Colors.white),
                      )
                    : const Text(
                        "Send Invite",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        counterText: "",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}