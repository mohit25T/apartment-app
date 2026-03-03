import 'package:flutter/material.dart';
import 'package:flutter/src/material/dropdown.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api/api_service.dart';
import '../core/widgets/walking_loader.dart';
import '../core/theme/app_theme.dart';

class ComplaintCreateScreen extends StatefulWidget {
  const ComplaintCreateScreen({super.key});

  @override
  State<ComplaintCreateScreen> createState() => _ComplaintCreateScreenState();
}

class _ComplaintCreateScreenState extends State<ComplaintCreateScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  String category = "GENERAL";
  String priority = "MEDIUM";

  bool loading = false;
  List<XFile> selectedImages = []; // ✅ FIXED

  final ImagePicker _picker = ImagePicker();

  /* ================= PICK IMAGES ================= */

  Future<void> pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 70);

    setState(() {
      selectedImages.addAll(images);
    });
  }

  void removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  /* ================= SUBMIT ================= */

  Future<void> submitComplaint() async {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title is required")),
      );
      return;
    }

    setState(() => loading = true);

    final response = await ApiService.multipart(
      "/complaints/create",
      {
        "category": category,
        "priority": priority,
        "title": titleController.text.trim(),
        "description": descriptionController.text.trim(),
      },
      xFiles: selectedImages.isNotEmpty ? selectedImages : null, // ✅ FIXED
      fileFieldName: "images",
    );

    setState(() => loading = false);

    if (response != null && response["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Complaint Submitted Successfully")),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response?["message"] ?? "Something went wrong"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Raise Complaint"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Title",
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Description",
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              // value: category,
              items: const [
                DropdownMenuItem(value: "PLUMBING", child: Text("Plumbing")),
                DropdownMenuItem(
                    value: "ELECTRICITY", child: Text("Electricity")),
                DropdownMenuItem(value: "SECURITY", child: Text("Security")),
                DropdownMenuItem(value: "CLEANING", child: Text("Cleaning")),
                DropdownMenuItem(value: "LIFT", child: Text("Lift")),
                DropdownMenuItem(value: "OTHER", child: Text("Other")),
              ],
              onChanged: (value) => setState(() => category = value!),
              decoration: const InputDecoration(
                labelText: "Category",
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
              onChanged: (value) => setState(() => priority = value!),
              decoration: const InputDecoration(
                labelText: "Priority",
              ),
            ),
            const SizedBox(height: 20),

            /// ADD IMAGES BUTTON
            ElevatedButton.icon(
              onPressed: pickImages,
              icon: const Icon(Icons.image),
              label: const Text("Add Images"),
            ),

            const SizedBox(height: 12),

            /// IMAGE PREVIEW
            if (selectedImages.isNotEmpty)
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              selectedImages[index].path,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => removeImage(index),
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      ],
                    );
                  },
                ),
              ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : submitComplaint,
                child: loading
                    ? const WalkingLoader(
                        size: 40,
                        color: Colors.white,
                      )
                    : const Text("Submit Complaint"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
