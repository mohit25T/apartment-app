import 'package:flutter/material.dart';
import '../core/api/api_service.dart';

class InviteGuardScreen extends StatefulWidget {
  const InviteGuardScreen({super.key});

  @override
  State<InviteGuardScreen> createState() => _InviteGuardScreenState();
}

class _InviteGuardScreenState extends State<InviteGuardScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController(); // ✅ NEW
  final mobileController = TextEditingController();

  bool loading = false;

  Future<void> inviteGuard() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty || // ✅ email validation
        mobileController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter name, email and valid mobile")),
      );
      return;
    }

    setState(() => loading = true);

    final response = await ApiService.post(
      "/invites/invite-guard",
      {
        "name": nameController.text.trim(),
        "email": emailController.text.trim().toLowerCase(), // ✅ ADDED
        "mobile": mobileController.text.trim(),
      },
    );

    setState(() => loading = false);

    if (response["message"] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response["message"])),
      );

      nameController.clear();
      emailController.clear(); // ✅ clear
      mobileController.clear();

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response["message"] ?? "Failed to invite guard"),
        ),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose(); // ✅ dispose
    mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Invite Guard")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 👤 NAME
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Guard Name",
              ),
            ),

            const SizedBox(height: 15),

            // 📧 EMAIL (NEW)
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email Address",
              ),
            ),

            const SizedBox(height: 15),

            // 📱 MOBILE
            TextField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: "Mobile Number",
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: loading ? null : inviteGuard,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Send Invite"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
