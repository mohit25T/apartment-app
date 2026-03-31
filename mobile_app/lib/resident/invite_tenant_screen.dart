import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';

class InviteTenantScreen extends StatefulWidget {
  const InviteTenantScreen({super.key});

  @override
  State<InviteTenantScreen> createState() => _InviteTenantScreenState();
}

class _InviteTenantScreenState extends State<InviteTenantScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  String? flatNo;
  String? wingNo;
  bool loading = false;
  bool loadingFlat = true;

  @override
  void initState() {
    super.initState();
    fetchFlatNumber();
  }

  Future<void> fetchFlatNumber() async {
    final response = await ApiService.get("/users/profile");

    if (response != null && response["success"] == true) {
      flatNo = response["user"]["flatNo"];
      wingNo = response["user"]["wingNo"];
    }

    setState(() => loadingFlat = false);
  }

  Future<void> inviteTenant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final response = await ApiService.post(
      "/invites/invite-resident",
      {
        "name": nameController.text.trim(),
        "mobile": mobileController.text.trim(),
        "email": emailController.text.trim(),
        "flatNo": flatNo,
        "wingNo": wingNo,
        "role": "TENANT"
      },
    );

    setState(() => loading = false);

    if (response != null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Success"),
          content: const Text("Tenant invite sent successfully."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to send invite"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Invite Tenant"),
      ),
      body: loadingFlat
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Icon(Icons.person_add_alt_1_rounded,
                          size: 60, color: Theme.of(context).primaryColor),
                      const SizedBox(height: 20),

                      // 🔒 Flat Number (Auto-fetched)
                      TextFormField(
                        initialValue: flatNo ?? "",
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: "Flat Number",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: "Tenant Name",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? "Enter name"
                            : null,
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: mobileController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: "Mobile Number",
                          border: OutlineInputBorder(),
                          counterText: "",
                        ),
                        validator: (value) => value == null || value.length < 10
                            ? "Enter valid mobile number"
                            : null,
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: "Email Address",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || !value.contains("@")
                                ? "Enter valid email"
                                : null,
                      ),

                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: loading ? null : inviteTenant,
                          child: loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  "Send Invite",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
