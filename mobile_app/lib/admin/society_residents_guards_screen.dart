import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/walking_loader.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Residents & Guards"),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: WalkingLoader(size: 60))
          : users.isEmpty
              ? const Center(child: Text("No users found"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final u = users[index];

                    final role = (u["roles"] != null && u["roles"].isNotEmpty)
                        ? u["roles"][0]
                        : "N/A";

                    final bool isBlocked = u["status"] == "BLOCKED";
                    final bool isGuard = role == "GUARD";

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isGuard 
                                      ? Colors.blue.withOpacity(0.1) 
                                      : Colors.orange.withOpacity(0.1),
                                  child: Icon(
                                    isGuard ? Icons.security : Icons.person,
                                    color: isGuard ? Colors.blue : Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        u["name"] ?? "User",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        role,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isBlocked 
                                        ? Colors.red.withOpacity(0.1) 
                                        : Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isBlocked ? "BLOCKED" : "ACTIVE",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isBlocked ? Colors.red : Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _infoRow(Icons.phone_android, u["mobile"] ?? "N/A"),
                                    const SizedBox(height: 4),
                                    _infoRow(Icons.email_outlined, u["email"] ?? "N/A"),
                                  ],
                                ),
                                OutlinedButton(
                                  onPressed: () => toggleBlockUser(u["_id"], isBlocked),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isBlocked ? Colors.green : Colors.red,
                                    side: BorderSide(color: isBlocked ? Colors.green : Colors.red),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                  ),
                                  child: Text(isBlocked ? "Unblock" : "Block"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
