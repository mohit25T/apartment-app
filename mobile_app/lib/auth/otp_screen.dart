import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/storage/token_storage.dart';
import '../core/storage/role_storage.dart';
import '../services/notification_service.dart';
import '../core/widgets/walking_loader.dart';
import '../core/storage/user_storage.dart';
import '../core/widgets/fade_in_slide.dart';
import '../core/services/socket_service.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpController = TextEditingController();
  bool loading = false;
  bool resending = false;
  int _secondsRemaining = 300;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _secondsRemaining = 300;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final secs = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  Future<void> _resendOtp(String mobile) async {
    setState(() => resending = true);
    
    final response = await ApiService.post(
      "/auth/resend-user-otp",
      {"mobile": mobile},
    );

    setState(() => resending = false);

    if (response != null && response["message"] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response["message"]), backgroundColor: Colors.green),
      );
      _startTimer();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to resend OTP"), backgroundColor: AppColors.error),
      );
    }
  }

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
      // 1. Save tokens
      await TokenStorage.saveToken(response["token"]);
      if (response["refreshToken"] != null) {
        await TokenStorage.saveRefreshToken(response["refreshToken"]);
      }

      // 2. Save roles
      final List roles = response["roles"] ?? [];
      final List<String> normalizedRoles =
          roles.map((r) => r.toString().toUpperCase()).toList();
      await RoleStorage.saveRoles(normalizedRoles);

      // 3. Save login state
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

      // 🛡️ SAVE GUARD SHIFT DATA
      if (normalizedRoles.contains("GUARD")) {
        if (response["shiftStartTime"] != null) {
          await prefs.setString("shiftStartTime", response["shiftStartTime"]);
        }
        if (response["shiftEndTime"] != null) {
          await prefs.setString("shiftEndTime", response["shiftEndTime"]);
        }
        if (response["shiftType"] != null) {
          await prefs.setString("shiftType", response["shiftType"]);
        }
      }

      // 🔔 INIT FCM COMPLETELY
      await NotificationService.initFcm();

      // 4. FETCH PROFILE TO CHECK PHOTO
      final profileResponse = await ApiService.get("/users/me");
      bool requiresProfilePhoto = false;

      if (profileResponse != null && profileResponse["requiresProfilePhoto"] != null) {
        requiresProfilePhoto = profileResponse["requiresProfilePhoto"];
      }

      // SAVE USER BASIC INFO
      if (profileResponse != null && profileResponse["user"] != null) {
        await UserStorage.saveUser(
          name: profileResponse["user"]["name"],
          email: profileResponse["user"]["email"],
          mobile: profileResponse["user"]["mobile"],
        );
      }

      if (mounted) {
        setState(() => loading = false);
      }

      // 🔌 Initialize Socket
      SocketService().init();

      // 5. IF PROFILE PHOTO REQUIRED
      if (requiresProfilePhoto == true) {
        if (mounted) Navigator.pushReplacementNamed(context, "/upload-profile-photo");
        return;
      }

      // 6. NORMAL NAVIGATION
      if (mounted) {
        if (normalizedRoles.contains("ADMIN")) {
          Navigator.pushReplacementNamed(context, "/admin");
        } else if (normalizedRoles.contains("GUARD")) {
          Navigator.pushReplacementNamed(context, "/guard");
        } else {
          Navigator.pushReplacementNamed(context, "/resident");
        }
      }
    } else {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response?["message"] ?? "OTP verification failed"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String mobile = ModalRoute.of(context)!.settings.arguments as String;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Modern Header
            Container(
              height: 320,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFF1E88E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    FadeInSlide(
                      delay: 0.1,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_person_rounded,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const FadeInSlide(
                      delay: 0.2,
                      child: Text(
                        "OTP Verification",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeInSlide(
                      delay: 0.3,
                      child: Text(
                        "Sent to +91 $mobile",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Modern OTP Input Field
                  FadeInSlide(
                    delay: 0.4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 16,
                            color: AppColors.primary,
                          ),
                          decoration: const InputDecoration(
                            counterText: "",
                            hintText: "______",
                            hintStyle: TextStyle(
                              letterSpacing: 16,
                              color: Colors.grey,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Timer & Resend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_outlined, size: 20, color: _secondsRemaining > 0 ? AppColors.primary : Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(_secondsRemaining),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _secondsRemaining > 0 ? AppColors.primary : Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Center(
                    child: TextButton(
                      onPressed: (_secondsRemaining == 0 && !resending) ? () => _resendOtp(mobile) : null,
                      child: Text(
                        resending ? "Resending..." : "Resend OTP",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _secondsRemaining == 0 ? AppColors.primary : Colors.grey,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const SizedBox(height: 40),

                  // Action Button
                  FadeInSlide(
                    delay: 0.5,
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: loading ? null : () => verifyOtp(mobile),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 5,
                          shadowColor: AppColors.primary.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 40,
                                height: 40,
                                child: WalkingLoader(
                                  size: 40,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Verify & Proceed",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}