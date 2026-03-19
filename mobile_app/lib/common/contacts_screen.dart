import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/walking_loader.dart';
import '../core/storage/role_storage.dart';

import '../admin/add_contact_screen.dart';
import '../admin/edit_contact_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List contacts = [];
  List filteredContacts = [];
  bool loading = true;

  bool isAdmin = false;

  static const cacheKey = "contacts_cache";

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    checkAdmin();
    loadCachedContacts();
    loadContacts();
  }

  // 🔐 Check Role
  Future<void> checkAdmin() async {
    final roles = await RoleStorage.getRoles();

    if (mounted) {
      setState(() {
        isAdmin = roles.contains("ADMIN");
      });
    }
  }

  // 📦 Load Cache
  Future<void> loadCachedContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(cacheKey);

    if (cached != null) {
      setState(() {
        contacts = jsonDecode(cached);
        filteredContacts = contacts;
        loading = false;
      });
    }
  }

  // 💾 Save Cache
  Future<void> saveCache(List data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cacheKey, jsonEncode(data));
  }

  // 🌐 Fetch API
  Future<void> loadContacts() async {
    final res = await ApiService.get("/contacts");

    if (res != null && res["contacts"] != null) {
      setState(() {
        contacts = res["contacts"];
        filteredContacts = contacts;
        loading = false;
      });

      saveCache(contacts);
    }
  }

  // 🔍 Search
  void searchContacts(String query) {
    final results = contacts.where((c) {
      return c["name"]
          .toString()
          .toLowerCase()
          .contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredContacts = results;
    });
  }

  // 📞 Call
  Future<void> makeCall(String phone) async {
    final Uri url = Uri.parse("tel:$phone");

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  // 📂 Filter
  List getCategory(String category) {
    return filteredContacts
        .where((c) => c["category"] == category)
        .toList();
  }

  // ❌ Delete
  Future<void> deleteContact(String id) async {
    await ApiService.delete("/contacts/$id");
    loadContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("Common Contacts"),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadContacts,
          )
        ],
      ),

      // ➕ Admin Only
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddContactScreen(),
                  ),
                );

                if (result != null) loadContacts();
              },
            )
          : null,

      body: loading
          ? const Center(child: WalkingLoader(size: 60))
          : filteredContacts.isEmpty
              ? const Center(child: Text("No contacts found"))
              : RefreshIndicator(
                  onRefresh: loadContacts,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [

                        // 🔍 Search
                        TextField(
                          controller: searchController,
                          onChanged: searchContacts,
                          decoration: InputDecoration(
                            hintText: "Search contacts...",
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Expanded(
                          child: ListView(
                            children: [

                              buildSection(
                                "🚨 Emergency",
                                getCategory("emergency"),
                              ),

                              buildSection(
                                "🛠 Maintenance",
                                getCategory("maintenance"),
                              ),

                              buildSection(
                                "🏢 Society",
                                getCategory("society"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  // 🧱 Section
  Widget buildSection(String title, List data) {
    if (data.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...data.map((c) => buildContactCard(c)).toList(),
        const SizedBox(height: 20),
      ],
    );
  }

  // 📇 Card
  Widget buildContactCard(dynamic contact) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: const Icon(Icons.phone, color: Colors.green),
        ),
        title: Text(
          contact["name"],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(contact["phone"]),

        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [

            // 📞 Call
            IconButton(
              icon: const Icon(Icons.call, color: Colors.green),
              onPressed: () => makeCall(contact["phone"]),
            ),

            // ✏️ Edit (Admin only)
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EditContactScreen(contact: contact),
                    ),
                  );

                  if (result == true) loadContacts();
                },
              ),

            // ❌ Delete (Admin only)
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => deleteContact(contact["_id"]),
              ),
          ],
        ),
      ),
    );
  }
}