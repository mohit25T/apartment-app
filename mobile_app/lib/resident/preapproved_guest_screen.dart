import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/walking_loader.dart';

class PreApprovedGuestScreen extends StatefulWidget {
  const PreApprovedGuestScreen({super.key});

  @override
  State<PreApprovedGuestScreen> createState() => _PreApprovedGuestScreenState();
}

class _PreApprovedGuestScreenState extends State<PreApprovedGuestScreen> {
  final nameController = TextEditingController();
  final mobileController = TextEditingController();

  bool loading = false;
  String? otp;

  Future<void> createGuest() async {
    if (nameController.text.isEmpty || mobileController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Enter valid details"),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => loading = true);

    final response = await ApiService.post(
      "/visitors/preapprove",
      {
        "guestName": nameController.text.trim(),
        "guestMobile": mobileController.text.trim(),
      },
    );
    print('...$nameController');
    print('...$mobileController');
    setState(() => loading = false);

    if (response["otp"] != null) {
      setState(() {
        otp = response["otp"];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response["message"] ?? "Failed"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Pre-Approved Guest"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: otp == null ? _buildForm() : _buildOtpView(),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Invite a Guest",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Generate an OTP for your guest to allow seamless entry at the gate.",
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 32),

        TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: "Guest Name",
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: mobileController,
          maxLength: 10,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: "Guest Mobile",
            prefixIcon: const Icon(Icons.phone_android_outlined),
            counterText: "",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: loading ? null : createGuest,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: loading
                ? const SizedBox(
                    width: 30,
                    height: 30,
                    child: WalkingLoader(size: 30, color: Colors.white),
                  )
                : const Text("Generate OTP", style: TextStyle(fontSize: 16)),
          ),
        )
      ],
    );
  }

  Widget _buildOtpView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user_rounded, size: 64, color: AppColors.accent),
            const SizedBox(height: 24),
            const Text(
              "Access Token Generated",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Share this OTP with your guest",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
              ),
              child: Text(
                otp!,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    otp = null;
                    nameController.clear();
                    mobileController.clear();
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Generate Another"),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
