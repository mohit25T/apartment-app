import 'package:flutter/material.dart';

import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';

class EditContactScreen extends StatefulWidget {
  final Map contact;

  const EditContactScreen({super.key, required this.contact});

  @override
  State<EditContactScreen> createState() => _EditContactScreenState();
}

class _EditContactScreenState extends State<EditContactScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController roleController;

  late String selectedCategory;

  bool loading = false;
  bool deleting = false;

  @override
  void initState() {
    super.initState();

    nameController =
        TextEditingController(text: widget.contact["name"]);
    phoneController =
        TextEditingController(text: widget.contact["phone"]);
    roleController =
        TextEditingController(text: widget.contact["role"] ?? "");

    selectedCategory = widget.contact["category"];
  }

  // ✏️ UPDATE
  Future<void> updateContact() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final body = {
      "name": nameController.text.trim(),
      "phone": phoneController.text.trim(),
      "category": selectedCategory,
      "role": roleController.text.trim(),
    };

    final res = await ApiService.patch(
      "/contacts/${widget.contact["_id"]}",
      body: body,
    );

    setState(() => loading = false);

    if (res != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contact updated successfully")),
      );
      Navigator.pop(context, true); // 🔥 return success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Update failed")),
      );
    }
  }

  // ❌ DELETE (WITH CONFIRMATION)
  Future<void> deleteContact() async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Contact"),
        content: const Text(
            "Are you sure you want to delete this contact?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => deleting = true);

    await ApiService.delete(
      "/contacts/${widget.contact["_id"]}",
    );

    setState(() => deleting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Contact deleted")),
    );

    Navigator.pop(context, true); // 🔥 return success
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("Edit Contact"),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: deleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.delete),
            onPressed: deleting ? null : deleteContact,
          )
        ],
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

              // 📂 Category
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

              // ✏️ Update Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: loading ? null : updateContact,
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Update Contact"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}