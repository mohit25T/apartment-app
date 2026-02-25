import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/storage/token_storage.dart';
import '../core/storage/role_storage.dart';
import '../services/notification_service.dart';
import '../core/widgets/walking_loader.dart';
import '../core/storage/user_storage.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpController = TextEditingController();
  bool loading = false;

  /// =================================
  /// VERIFY OTP
  /// =================================
  Future<void> verifyOtp(String mobile) async {
    if (otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid OTP")),
      );
      return;
    }

    setState(() => loading = true);

    final String? fcmToken = await NotificationService.getFcmTokenOnly();

    final response = await ApiService.post(
      "/auth/verify-user-otp",
      {
        "mobile": mobile,
        "otp": otpController.text,
        "fcmToken": fcmToken,
      },
    );

    if (response != null && response["token"] != null) {
      // =================================
      // 1️⃣ SAVE TOKEN
      // =================================
      await TokenStorage.saveToken(response["token"]);

      // =================================
      // 2️⃣ SAVE ROLES
      // =================================
      final List roles = response["roles"] ?? [];
      final List<String> normalizedRoles =
          roles.map((r) => r.toString().toUpperCase()).toList();

      await RoleStorage.saveRoles(normalizedRoles);

      // =================================
      // 3️⃣ SAVE LOGIN STATE
      // =================================
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setBool('admin_mode', normalizedRoles.contains("ADMIN"));

      if (normalizedRoles.contains("ADMIN")) {
        await prefs.setString('role', 'ADMIN');
      } else if (normalizedRoles.contains("GUARD")) {
        await prefs.setString('role', 'GUARD');
      } else if (normalizedRoles.contains("OWNER")) {
        await prefs.setString('role', 'OWNER');
      } else if (normalizedRoles.contains("TENANT")) {
        await prefs.setString('role', 'TENANT');
      } else {
        await prefs.setString('role', 'OWNER');
      }

      // =================================
      // 🔔 INIT FCM COMPLETELY
      // =================================
      await NotificationService.initFcm();

      // =================================
      // 4️⃣ FETCH PROFILE TO CHECK PHOTO
      // =================================
      final profileResponse = await ApiService.get("/users/me");

      bool requiresProfilePhoto = false;

      if (profileResponse != null &&
          profileResponse["requiresProfilePhoto"] != null) {
        requiresProfilePhoto = profileResponse["requiresProfilePhoto"];
      }

      // Save user basic info
      if (profileResponse != null && profileResponse["user"] != null) {
        await UserStorage.saveUser(
          name: profileResponse["user"]["name"],
          email: profileResponse["user"]["email"],
          mobile: profileResponse["user"]["mobile"],
        );
      }

      setState(() => loading = false);

      // =================================
      // 5️⃣ IF PROFILE PHOTO REQUIRED
      // =================================
      if (requiresProfilePhoto == true) {
        Navigator.pushReplacementNamed(context, "/upload-profile-photo");
        return;
      }

      // =================================
      // 6️⃣ NORMAL NAVIGATION
      // =================================
      if (normalizedRoles.contains("ADMIN")) {
        Navigator.pushReplacementNamed(context, "/admin");
      } else if (normalizedRoles.contains("GUARD")) {
        Navigator.pushReplacementNamed(context, "/guard");
      } else {
        Navigator.pushReplacementNamed(context, "/resident");
      }
    } else {
      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response?["message"] ?? "OTP verification failed"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String mobile = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Verify OTP"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Icon(
                Icons.lock_person_rounded,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                "OTP Verification",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Enter the OTP sent to +91 $mobile",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                decoration: const InputDecoration(
                  counterText: "",
                  hintText: "______",
                  hintStyle: TextStyle(letterSpacing: 8, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: loading ? null : () => verifyOtp(mobile),
                  child: loading
                      ? const SizedBox(
                          width: 40,
                          height: 40,
                          child: WalkingLoader(size: 40, color: Colors.white),
                        )
                      : const Text("Verify & Proceed"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
