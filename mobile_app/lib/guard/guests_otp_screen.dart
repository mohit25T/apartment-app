import 'package:flutter/material.dart';
import '../core/api/api_service.dart';

class GuestOtpScreen extends StatefulWidget {
  const GuestOtpScreen({super.key});

  @override
  State<GuestOtpScreen> createState() => _GuestOtpScreenState();
}

class _GuestOtpScreenState extends State<GuestOtpScreen> {
  final otpController = TextEditingController();
  bool loading = false;

  Future<void> verifyOtp() async {
    setState(() => loading = true);

    final response = await ApiService.post(
      "/visitors/verify-otp",
      {"otp": otpController.text.trim()},
    );

    setState(() => loading = false);

    if (response["visitor"] != null) {
      // ✅ OTP verified → redirect to visitors page
      Navigator.pushReplacementNamed(context, "/visitors");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response["message"] ?? "Invalid OTP"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Guest OTP Entry")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Enter OTP",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : verifyOtp,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Verify OTP"),
            ),
          ],
        ),
      ),
    );
  }
}
