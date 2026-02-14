import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/walking_loader.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController mobileController = TextEditingController();
  bool loading = false;

  final String supportPhone = "tel:+917043622519";
  final String supportWhatsApp =
      "whatsapp://send?phone=917043622519&text=Hi%2C%20I%27m%20facing%20an%20issue%20while%20logging%20into%20the%20app.";
  final String supportEmail = "mailto:mohittopiya2564@gmail.com";

  Future<void> sendOtp() async {
    if (mobileController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid mobile number")),
      );
      return;
    }

    setState(() => loading = true);

    final response = await ApiService.post(
      "/auth/send-user-otp",
      {"mobile": mobileController.text},
    );

    setState(() => loading = false);

    if (response["message"] == "OTP sent successfully to email") {
      Navigator.pushNamed(
        context,
        "/otp",
        arguments: mobileController.text,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response["message"] ?? "OTP failed",
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> openLink(String url) async {
    final uri = Uri.parse(url);

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to open support option")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Header
              Icon(
                Icons.apartment_rounded,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 20),
              Text(
                "Welcome Back",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Enter your mobile number to continue",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // Input Field
              TextField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: "Mobile Number",
                  hintText: "Enter 10 digit number",
                  prefixIcon: const Icon(Icons.phone_android),
                  prefixText: "+91 ",
                ),
              ),
              const SizedBox(height: 24),
              
              // Action Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: loading ? null : sendOtp,
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
                      : const Text("Get OTP"),
                ),
              ),

              // Support Section
              const SizedBox(height: 60),
              Row(
                children: [
                   Expanded(child: Divider(color: Colors.grey.shade300)),
                   Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Need Help?",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ),
                   Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSupportOption(
                    icon: Icons.call,
                    label: "Call",
                    onTap: () => openLink(supportPhone),
                  ),
                  _buildSupportOption(
                    icon: Icons.chat, // Assuming chat represents WhatsApp
                    label: "WhatsApp",
                    onTap: () => openLink(supportWhatsApp),
                    color: Colors.green,
                  ),
                  _buildSupportOption(
                    icon: Icons.email,
                    label: "Email",
                    onTap: () => openLink(supportEmail),
                    color: Colors.redAccent,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color ?? AppColors.primary, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
