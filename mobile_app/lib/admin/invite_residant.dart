import 'package:flutter/material.dart';
import '../core/api/api_service.dart';

class InviteResidentScreen extends StatefulWidget {
  const InviteResidentScreen({super.key});

  @override
  State<InviteResidentScreen> createState() => _InviteResidentScreenState();
}

class _InviteResidentScreenState extends State<InviteResidentScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController emailController = TextEditingController(); // ✅ NEW
  final TextEditingController flatController = TextEditingController();

  bool loading = false;

  Future<void> inviteResident() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty || // ✅ email check
        mobileController.text.length != 10 ||
        flatController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter name, email, mobile number and flat number"),
        ),
      );
      return;
    }

    setState(() => loading = true);

    final response = await ApiService.post(
      "/invites/invite-resident",
      {
        "name": nameController.text.trim(),
        "email": emailController.text.trim().toLowerCase(), // ✅ ADDED
        "mobile": mobileController.text.trim(),
        "flatNo": flatController.text.trim(),
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
      flatController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong")),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose(); // ✅ dispose
    mobileController.dispose();
    flatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Invite Resident"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            // 👤 NAME
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Resident Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // 📧 EMAIL (NEW)
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email Address",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // 🏠 FLAT NO
            TextField(
              controller: flatController,
              decoration: const InputDecoration(
                labelText: "Flat Number (e.g. A-203)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            // 📱 MOBILE
            TextField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: "Mobile Number",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : inviteResident,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Invite Resident",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
