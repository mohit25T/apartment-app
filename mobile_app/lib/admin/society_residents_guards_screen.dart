import 'package:flutter/material.dart';
import '../core/api/api_service.dart';

class SocietyUsersScreen extends StatefulWidget {
  const SocietyUsersScreen({super.key});

  @override
  State<SocietyUsersScreen> createState() => _SocietyUsersScreenState();
}

class _SocietyUsersScreenState extends State<SocietyUsersScreen> {
  bool loading = true;
  List users = [];

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    setState(() => loading = true);

    final response = await ApiService.get("/users/by-society");

    if (response != null) {
      setState(() {
        users = response;
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  Future<void> toggleBlockUser(String userId, bool isBlocked) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isBlocked ? "Unblock User?" : "Block User?"),
        content: Text(
          isBlocked
              ? "Do you want to unblock this user?"
              : "Do you want to block this user?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isBlocked ? Colors.green : Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(isBlocked ? "Unblock" : "Block"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ApiService.patch("/block/user/$userId");

    await loadUsers(); // 🔄 refresh list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Residents & Guards"),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? const Center(child: Text("No users found"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final u = users[index];

                    final role = (u["roles"] != null && u["roles"].isNotEmpty)
                        ? u["roles"][0]
                        : "N/A";

                    final bool isBlocked = u["status"] == "BLOCKED";

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          role == "GUARD" ? Icons.security : Icons.person,
                        ),
                        title: Text(u["name"] ?? "User"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Role: $role"),
                            Text("Mobile: ${u["mobile"] ?? "N/A"}"),
                            Text("Email: ${u["email"] ?? "N/A"}"),
                            Text(
                              "Status: ${u["status"] ?? "N/A"}",
                              style: TextStyle(
                                color: isBlocked ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  toggleBlockUser(u["_id"], isBlocked),
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    isBlocked ? Colors.green : Colors.red,
                              ),
                              child: Text(
                                isBlocked ? "UNBLOCK" : "BLOCK",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

}
