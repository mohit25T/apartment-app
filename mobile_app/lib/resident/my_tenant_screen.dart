import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/walking_loader.dart';

class ResidentMyTenantScreen extends StatefulWidget {
  const ResidentMyTenantScreen({super.key});

  @override
  State<ResidentMyTenantScreen> createState() => _ResidentMyTenantScreenState();
}

class _ResidentMyTenantScreenState extends State<ResidentMyTenantScreen> {
  bool loading = true;
  bool removing = false;

  Map<String, dynamic>? tenant;
  String? type; // ACTIVE or PENDING

  @override
  void initState() {
    super.initState();
    fetchTenant();
  }

  Future<void> fetchTenant() async {
    setState(() => loading = true);

    final response = await ApiService.get("/users/my-tenant");

    if (response != null && response["success"] == true) {
      tenant = response["data"];
      type = response["type"];
    } else {
      tenant = null;
    }

    setState(() => loading = false);
  }

  Future<void> _confirmRemoveTenant() async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Tenant"),
        content: const Text("Are you sure you want to remove this tenant?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Remove"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => removing = true);

      final response = await ApiService.delete("/users/remove-tenant");

      setState(() => removing = false);

      if (response != null && response["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Tenant removed successfully"),
          ),
        );

        fetchTenant(); // Refresh UI
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response?["message"] ?? "Failed to remove tenant"),
          ),
        );
      }
    }
  }

  Color getStatusColor() {
    if (type == "ACTIVE") return Colors.green;
    if (type == "PENDING") return Colors.orange;
    return Colors.grey;
  }

  String getStatusText() {
    if (type == "ACTIVE") return "Active Tenant";
    if (type == "PENDING") return "Pending Registration";
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("My Tenant"),
      ),
      body: loading
          ? const Center(
              child: WalkingLoader(
                size: 60,
                color: AppColors.primary,
              ),
            )
          : tenant == null
              ? const Center(
                  child: Text(
                    "No Tenant Assigned",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 30,
                                child: Icon(
                                  Icons.person,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  tenant!["name"] ?? "",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: getStatusColor().withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  getStatusText(),
                                  style: TextStyle(
                                    color: getStatusColor(),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 30),
                          _buildInfoRow("Mobile", tenant!["mobile"]),
                          const SizedBox(height: 12),
                          _buildInfoRow("Email", tenant!["email"]),
                          const SizedBox(height: 12),
                          _buildInfoRow("Flat No", tenant!["flatNo"]),
                          const SizedBox(height: 30),

                          // 🔥 REMOVE BUTTON (Only for ACTIVE tenant)
                          if (type == "ACTIVE")
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: removing
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.delete_outline),
                                label: Text(
                                    removing ? "Removing..." : "Remove Tenant"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed:
                                    removing ? null : _confirmRemoveTenant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Row(
      children: [
        Text(
          "$label: ",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value?.toString() ?? "-",
            style: const TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
