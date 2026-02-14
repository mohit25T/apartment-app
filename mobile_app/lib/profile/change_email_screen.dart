import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/storage/token_storage.dart';

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  bool isLoading = true;
  bool submitting = false;

  String currentEmail = "";
  String newEmail = "";
  String otp = "";

  int step = 1; // 1 = request OTP, 2 = verify OTP
  String error = "";
  String message = "";

  @override
  void initState() {
    super.initState();
    _loadCurrentEmail();
  }

  /* ===============================
     FETCH CURRENT EMAIL
  =============================== */
  Future<void> _loadCurrentEmail() async {
    final response = await ApiService.get("/auth/me");

    if (response != null && response["email"] != null) {
      setState(() {
        currentEmail = response["email"];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  /* ===============================
     STEP 1: REQUEST EMAIL CHANGE
  =============================== */
  Future<void> _requestEmailChange() async {
    setState(() {
      error = "";
      message = "";
      submitting = true;
    });

    if (newEmail.isEmpty) {
      setState(() {
        error = "New email is required";
        submitting = false;
      });
      return;
    }

    if (newEmail == currentEmail) {
      setState(() {
        error = "New email must be different from current email";
        submitting = false;
      });
      return;
    }

    final response = await ApiService.post(
      "/auth/request-email-change",
      {"newEmail": newEmail},
    );

    setState(() => submitting = false);

    if (response["message"] != null) {
      setState(() {
        step = 2; // 🔁 MOVE TO STEP 2
        message = response["message"];
      });
    } else {
      setState(() {
        error = response["message"] ?? "Failed to send OTP";
      });
    }
  }

  /* ===============================
     STEP 2: VERIFY OTP
  =============================== */
  Future<void> _verifyOtp() async {
    setState(() {
      error = "";
      message = "";
      submitting = true;
    });

    if (otp.isEmpty) {
      setState(() {
        error = "OTP is required";
        submitting = false;
      });
      return;
    }

    final response = await ApiService.post(
      "/auth/verify-email-change",
      {"otp": otp},
    );

    setState(() => submitting = false);

    if (response["message"] != null) {
      setState(() {
        message = "Email updated successfully. Please login again.";
      });

      // 🔐 CLEAR TOKEN & REDIRECT TO LOGIN
      await TokenStorage.clearToken();

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          "/login",
          (route) => false,
        );
      });
    } else {
      setState(() {
        error = response["message"] ?? "Invalid OTP";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Email"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /* ===== EMAIL INFO ===== */
                  Card(
                    child: Column(
                      children: [
                        _infoTile("Current Email", currentEmail),
                        if (step == 2) _infoTile("New Email", newEmail),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  /* ===== STEP 1 ===== */
                  if (step == 1)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextField(
                              decoration: const InputDecoration(
                                labelText: "New Email",
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (v) => newEmail = v.trim(),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed:
                                    submitting ? null : _requestEmailChange,
                                child: submitting
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text("Send OTP"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  /* ===== STEP 2 ===== */
                  if (step == 2)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextField(
                              decoration: const InputDecoration(
                                labelText: "Enter OTP",
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (v) => otp = v.trim(),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: submitting ? null : _verifyOtp,
                                child: submitting
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text("Verify & Update"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (error.isNotEmpty)
                    Text(error, style: const TextStyle(color: Colors.red)),
                  if (message.isNotEmpty)
                    Text(message, style: const TextStyle(color: Colors.green)),
                ],
              ),
            ),
    );
  }

  Widget _infoTile(String label, String value) {
    return ListTile(
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }
}
