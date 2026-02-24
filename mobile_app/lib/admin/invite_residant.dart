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

  bool loading = false;

  String selectedRole = "OWNER"; // ✅ Default role

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
        "flatNo": flatController.text.trim(),
        "role": selectedRole, // ✅ NEW
      },
    );

    setState(() => loading = false);

    if (response != null && response["message"] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response["message"]),
          backgroundColor: Colors.green,
        ),
      );

      nameController.clear();
      emailController.clear();
      mobileController.clear();
      flatController.clear();
      setState(() => selectedRole = "OWNER");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Something went wrong"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    flatController.dispose();
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
              "Invite Flat Member",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Send an invite to an Owner or Tenant.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            _buildTextField(nameController, "Full Name", Icons.person_outline),
            const SizedBox(height: 16),

            _buildTextField(
                emailController, "Email Address", Icons.email_outlined,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),

            _buildTextField(flatController, "Flat Number (e.g. A-203)",
                Icons.home_outlined),
            const SizedBox(height: 16),

            _buildTextField(
              mobileController,
              "Mobile Number",
              Icons.phone_android_outlined,
              keyboardType: TextInputType.phone,
              maxLength: 10,
            ),
            const SizedBox(height: 16),

            // ✅ NEW ROLE DROPDOWN
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(
                labelText: "Select Role",
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: const [
                DropdownMenuItem(
                  value: "OWNER",
                  child: Text("Owner"),
                ),
                DropdownMenuItem(
                  value: "TENANT",
                  child: Text("Tenant"),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedRole = value!;
                });
              },
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
