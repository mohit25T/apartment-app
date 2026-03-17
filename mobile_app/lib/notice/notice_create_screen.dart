import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/walking_loader.dart';

class NoticeCreateScreen extends StatefulWidget {
  const NoticeCreateScreen({super.key});

  @override
  State<NoticeCreateScreen> createState() => _NoticeCreateScreenState();
}

class _NoticeCreateScreenState extends State<NoticeCreateScreen> {
  final titleController = TextEditingController();
  final messageController = TextEditingController();

  String priority = "NORMAL";
  DateTime? expiryDate;
  bool loading = false;

  /* ===============================
     PICK EXPIRY DATE
  =============================== */

  Future<void> pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        expiryDate = picked;
      });
    }
  }

  /* ===============================
     CREATE NOTICE
  =============================== */

  Future<void> createNotice() async {
    if (titleController.text.trim().isEmpty ||
        messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields required")),
      );
      return;
    }

    setState(() => loading = true);

    final response = await ApiService.post(
      "/notices",
      {
        "title": titleController.text.trim(),
        "message": messageController.text.trim(),
        "priority": priority,
        "expiresAt": expiryDate?.toIso8601String(),
      },
    );

    setState(() => loading = false);

    if (response != null && response["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Notice created successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response?["message"] ?? "Failed to create notice"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    messageController.dispose();
    super.dispose();
  }

  /* ===============================
     BUILD UI
  =============================== */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("Create Notice"),
        backgroundColor: AppColors.primary,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// TITLE
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            /// MESSAGE
            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Message",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            /// PRIORITY
            DropdownButtonFormField<String>(
              value: priority,
              items: const [
                DropdownMenuItem(value: "NORMAL", child: Text("Normal")),
                DropdownMenuItem(value: "IMPORTANT", child: Text("Important")),
                DropdownMenuItem(value: "URGENT", child: Text("Urgent")),
              ],
              onChanged: (val) => setState(() => priority = val!),
              decoration: const InputDecoration(
                labelText: "Priority",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            /// EXPIRY DATE
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: pickExpiryDate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                ),
                child: Text(
                  expiryDate == null
                      ? "Pick Expiry Date"
                      : expiryDate.toString().split(" ").first,
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// CREATE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : createNotice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: loading
                    ? const WalkingLoader(size: 40, color: Colors.white)
                    : const Text(
                        "Create Notice",
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
