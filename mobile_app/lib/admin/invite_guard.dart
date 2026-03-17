import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/walking_loader.dart';

class InviteGuardScreen extends StatefulWidget {
  const InviteGuardScreen({super.key});

  @override
  State<InviteGuardScreen> createState() => _InviteGuardScreenState();
}

class _InviteGuardScreenState extends State<InviteGuardScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();

  bool loading = false;

  String shiftType = "DAY";
  TimeOfDay? shiftStart;
  TimeOfDay? shiftEnd;

  String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  Future<void> pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          shiftStart = picked;
        } else {
          shiftEnd = picked;
        }
      });
    }
  }

  Future<void> inviteGuard() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        mobileController.text.length != 10 ||
        shiftStart == null ||
        shiftEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Fill all fields including shift time"),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => loading = true);

    final response = await ApiService.post(
      "/invites/invite-guard",
      {
        "name": nameController.text.trim(),
        "email": emailController.text.trim().toLowerCase(),
        "mobile": mobileController.text.trim(),
        "shiftType": shiftType,
        "shiftStartTime": formatTime(shiftStart!),
        "shiftEndTime": formatTime(shiftEnd!),
      },
    );

    setState(() => loading = false);

    if (response["message"] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response["message"]),
          backgroundColor: Colors.green,
        ),
      );

      nameController.clear();
      emailController.clear();
      mobileController.clear();

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response["message"] ?? "Failed to invite guard"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Invite Guard"),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "New Security Guard",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Add a new security guard to the society system.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            _buildTextField(nameController, "Guard Name", Icons.person_outline),
            const SizedBox(height: 16),

            _buildTextField(
              emailController,
              "Email Address",
              Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 16),

            _buildTextField(
              mobileController,
              "Mobile Number",
              Icons.phone_android_outlined,
              keyboardType: TextInputType.phone,
              maxLength: 10,
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField(
              value: shiftType,
              decoration: InputDecoration(
                labelText: "Shift Type",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem(value: "DAY", child: Text("Day Shift")),
                DropdownMenuItem(value: "NIGHT", child: Text("Night Shift")),
              ],
              onChanged: (value) {
                setState(() {
                  shiftType = value.toString();
                });
              },
            ),

            const SizedBox(height: 16),

            _buildTimePicker(
              "Shift Start Time",
              shiftStart,
              () => pickTime(true),
            ),

            const SizedBox(height: 16),

            _buildTimePicker(
              "Shift End Time",
              shiftEnd,
              () => pickTime(false),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : inviteGuard,
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
                    : const Text(
                        "Send Invite",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        counterText: "",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay? time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        child: Text(
          time == null ? "Select Time" : formatTime(time),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
