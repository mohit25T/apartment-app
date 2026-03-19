import 'package:flutter/material.dart';

import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final roleController = TextEditingController();

  String selectedCategory = "emergency";
  bool loading = false;

  Future<void> createContact() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final body = {
      "name": nameController.text.trim(),
      "phone": phoneController.text.trim(),
      "category": selectedCategory,
      "role": roleController.text.trim(),
    };

    final res = await ApiService.post("/contacts", body);

    setState(() => loading = false);

    if (res != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contact added successfully")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to add contact")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("Add Contact"),
        backgroundColor: AppColors.primary,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              // 👤 Name
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Contact Name",
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 16),

              // 📞 Phone
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 16),

              // 🏷 Role
              TextFormField(
                controller: roleController,
                decoration: const InputDecoration(
                  labelText: "Role (Optional)",
                ),
              ),

              const SizedBox(height: 16),

              // 📂 Category Dropdown
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: "Category",
                ),
                items: const [
                  DropdownMenuItem(
                      value: "emergency", child: Text("Emergency")),
                  DropdownMenuItem(
                      value: "maintenance", child: Text("Maintenance")),
                  DropdownMenuItem(
                      value: "society", child: Text("Society")),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value!;
                  });
                },
              ),

              const SizedBox(height: 30),

              // ➕ Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: loading ? null : createContact,
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Add Contact"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}