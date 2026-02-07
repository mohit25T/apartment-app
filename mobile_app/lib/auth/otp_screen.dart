import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/storage/role_storage.dart';
import '../core/api/api_service.dart';
import '../core/storage/token_storage.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpController = TextEditingController();
  bool loading = false;

  Future<void> verifyOtp(String mobile) async {
    if (otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid OTP")),
      );
      return;
    }

    setState(() => loading = true);

    final response = await ApiService.post(
      "/auth/verify-user-otp",
      {
        "mobile": mobile,
        "otp": otpController.text,
      },
    );

    setState(() => loading = false);

    if (response["token"] != null) {
      // ✅ save token
      await TokenStorage.saveToken(response["token"]);

      // ✅ save roles (List<String>)
      final List roles = response["roles"] ?? [];
      await RoleStorage.saveRoles(List<String>.from(roles));

      // ✅ set default admin mode (if applicable)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("admin_mode", roles.contains("ADMIN"));

      // ✅ NEW: save login state
      await prefs.setBool('isLoggedIn', true);

      // ✅ NEW: save primary role for AuthCheckScreen
      if (roles.contains("ADMIN")) {
        await prefs.setString('role', 'admin');
      } else if (roles.contains("GUARD")) {
        await prefs.setString('role', 'guard');
      } else {
        await prefs.setString('role', 'resident');
      }

      // ✅ navigation (unchanged)
      if (roles.contains("ADMIN")) {
        Navigator.pushReplacementNamed(context, "/admin");
      } else if (roles.contains("GUARD")) {
        Navigator.pushReplacementNamed(context, "/guard");
      } else {
        Navigator.pushReplacementNamed(context, "/resident");
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response["message"] ?? "OTP verification failed"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String mobile = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify OTP"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text(
              "OTP sent to $mobile",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: "Enter OTP",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: loading ? null : () => verifyOtp(mobile),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Verify"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
