import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/storage/token_storage.dart';

class ChangeMobileScreen extends StatefulWidget {
  const ChangeMobileScreen({super.key});

  @override
  State<ChangeMobileScreen> createState() => _ChangeMobileScreenState();
}

class _ChangeMobileScreenState extends State<ChangeMobileScreen> {
  bool isLoading = true;
  bool submitting = false;

  String currentMobile = "";
  String newMobile = "";

  String error = "";
  String message = "";

  @override
  void initState() {
    super.initState();
    _loadCurrentMobile();
  }

  /* ===============================
     FETCH CURRENT MOBILE
  =============================== */
  Future<void> _loadCurrentMobile() async {
    final response = await ApiService.get("/users/profile");

    if (response != null && response["success"] == true) {
      setState(() {
        currentMobile = response["user"]["mobile"];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  /* ===============================
     UPDATE MOBILE
  =============================== */
  Future<void> _updateMobile() async {
    setState(() {
      error = "";
      message = "";
      submitting = true;
    });

    if (newMobile.isEmpty || newMobile.length != 10) {
      setState(() {
        error = "Enter valid 10-digit mobile number";
        submitting = false;
      });
      return;
    }

    if (newMobile == currentMobile) {
      setState(() {
        error = "New mobile must be different from current mobile";
        submitting = false;
      });
      return;
    }

    final response = await ApiService.put(
      "/user/mobile",
      {"mobile": newMobile},
    );

    setState(() => submitting = false);

    if (response["forceLogout"] == true) {
      setState(() {
        message = response["message"];
      });

      // 🔐 Auto logout
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
        error = response["message"] ?? "Failed to update mobile";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Mobile"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ===== CURRENT MOBILE =====
                  Card(
                    child: ListTile(
                      title: const Text("Current Mobile"),
                      trailing: Text(
                        currentMobile,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ===== NEW MOBILE =====
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            decoration: const InputDecoration(
                              labelText: "New Mobile Number",
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => newMobile = v.trim(),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: submitting ? null : _updateMobile,
                              child: submitting
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text("Update Mobile"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (error.isNotEmpty)
                    Text(
                      error,
                      style: const TextStyle(color: Colors.red),
                    ),

                  if (message.isNotEmpty)
                    Text(
                      message,
                      style: const TextStyle(color: Colors.green),
                    ),
                ],
              ),
            ),
    );
  }
}
