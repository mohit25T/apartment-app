import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController mobileController = TextEditingController();
  bool loading = false;

  // 🔹 Support details (can be moved to constants later)
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
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            TextField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Mobile Number",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : sendOtp,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Send OTP"),
            ),

            // 🔽 SUPPORT SECTION STARTS HERE
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              "Having trouble logging in?",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => openLink(supportPhone),
                  child: const Text("Call"),
                ),
                TextButton(
                  onPressed: () => openLink(supportWhatsApp),
                  child: const Text("WhatsApp"),
                ),
                TextButton(
                  onPressed: () => openLink(supportEmail),
                  child: const Text("Email"),
                ),
              ],
            ),
            // 🔼 SUPPORT SECTION ENDS HERE
          ],
        ),
      ),
    );
  }
}
