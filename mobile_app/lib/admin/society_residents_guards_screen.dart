import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/storage/user_storage.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/walking_loader.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  String? currentUserId;
  bool loading = true;
  List users = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadCurrentUser();
    await _fetchUsers();
  }

  Future<void> _loadCurrentUser() async {
    currentUserId = await UserStorage.getUserId();
  }

  Future<void> _fetchUsers() async {
    setState(() => loading = true);

    try {
      final response = await ApiService.get("/users/by-society");

      if (response != null && response["success"] == true) {
        users = response["users"] ?? [];
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to load users"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Something went wrong"),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => loading = false);
  }

  Future<void> toggleBlock(int index) async {
    final user = users[index];
    final userId = user["_id"];

    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          user["status"] == "BLOCKED" ? "Unblock User" : "Block User",
        ),
        content: Text(
          user["status"] == "BLOCKED"
              ? "Are you sure you want to unblock this user?"
              : "Are you sure you want to block this user?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => loading = true);

    final response = await ApiService.patch("/block/user/$userId");

    setState(() => loading = false);

    if (response != null && response["status"] != null) {
      setState(() {
        users[index]["status"] = response["status"];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response["message"] ?? "Updated")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update user"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool shouldShowBlockButton(Map<String, dynamic> user) {
    final List roles = user["roles"] ?? [];

    final bool isAdminOwnerOrTenant = roles.contains("ADMIN") &&
        (roles.contains("OWNER") || roles.contains("TENANT"));

    final bool isSuperAdmin = roles.contains("SUPER_ADMIN");

    final bool isSelf = user["_id"] == currentUserId;

    if (isAdminOwnerOrTenant || isSuperAdmin || isSelf) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Society Users"),
        backgroundColor: AppColors.primary,
      ),
      body: loading
          ? const Center(child: WalkingLoader(size: 60))
          : RefreshIndicator(
              onRefresh: _fetchUsers,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final bool showBlock = shouldShowBlockButton(user);

                  return Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          backgroundImage: user["profileImage"] != null
                              ? NetworkImage(
                                  user["profileImage"] +
                                      "?t=${DateTime.now().millisecondsSinceEpoch}",
                                )
                              : null,
                          child: user["profileImage"] == null
                              ? const Icon(Icons.person,
                                  color: AppColors.primary)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user["name"] ?? "User",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // EMAIL
                              if (user["email"] != null &&
                                  user["email"].toString().isNotEmpty)
                                Text(
                                  user["email"],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),

                              const SizedBox(height: 2),

                              // MOBILE
                              if (user["mobile"] != null &&
                                  user["mobile"].toString().isNotEmpty)
                                Text(
                                  user["mobile"].toString(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),

                              const SizedBox(height: 6),

                              Text(
                                (user["roles"] as List?)?.join(", ") ?? "",
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user["status"] ?? "ACTIVE",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: user["status"] == "BLOCKED"
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (showBlock)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: user["status"] == "BLOCKED"
                                  ? Colors.green
                                  : AppColors.error,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () => toggleBlock(index),
                            child: Text(
                              user["status"] == "BLOCKED" ? "Unblock" : "Block",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
