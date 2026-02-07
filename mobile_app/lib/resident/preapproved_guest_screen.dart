import 'package:flutter/material.dart';
import '../core/api/api_service.dart';

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
        const SnackBar(content: Text("Enter valid details")),
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
        SnackBar(content: Text(response["message"] ?? "Failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pre-Approved Guest")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: otp == null
            ? Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Guest Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: mobileController,
                    maxLength: 10,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Guest Mobile",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading ? null : createGuest,
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Generate OTP"),
                    ),
                  )
                ],
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Share this OTP with your guest",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      otp!,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 5,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
