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

  String priority = "MEDIUM";
  DateTime? expiryDate;
  bool loading = false;

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

  Future<void> createNotice() async {
    if (titleController.text.isEmpty || messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("All fields required"),
      ));
      return;
    }

    setState(() => loading = true);

    final response = await ApiService.post(
      "/notices",
      {
        "title": titleController.text,
        "message": messageController.text,
        "priority": priority,
        "expiresAt": expiryDate?.toIso8601String(),
      },
    );

    setState(() => loading = false);

    if (response["success"] == true) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Notice")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Title",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Message",
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              value: priority,
              items: const [
                DropdownMenuItem(value: "LOW", child: Text("Low")),
                DropdownMenuItem(value: "MEDIUM", child: Text("Medium")),
                DropdownMenuItem(value: "HIGH", child: Text("High")),
              ],
              onChanged: (val) => setState(() => priority = val!),
              decoration: const InputDecoration(
                labelText: "Priority",
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: pickExpiryDate,
              child: Text(expiryDate == null
                  ? "Pick Expiry Date"
                  : expiryDate.toString().split(" ").first),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : createNotice,
                child: loading
                    ? const WalkingLoader(
                        size: 40,
                        color: Colors.white,
                      )
                    : const Text("Create"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
