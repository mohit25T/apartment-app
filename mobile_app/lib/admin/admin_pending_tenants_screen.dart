import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';

class AdminPendingTenantsScreen extends StatefulWidget {
  const AdminPendingTenantsScreen({super.key});

  @override
  State<AdminPendingTenantsScreen> createState() =>
      _AdminPendingTenantsScreenState();
}

class _AdminPendingTenantsScreenState extends State<AdminPendingTenantsScreen> {
  List pendingTenants = [];
  bool loading = true;
  String? processingId; // 🔥 track which invite is processing

  @override
  void initState() {
    super.initState();
    fetchPendingTenants();
  }

  Future<void> fetchPendingTenants() async {
    setState(() => loading = true);

    final response = await ApiService.get("/admin/pending-tenants");

    if (response != null && response["success"] == true) {
      pendingTenants = response["data"];
    }

    setState(() => loading = false);
  }

  Future<void> refreshData() async {
    await fetchPendingTenants();
  }

  Future<void> approveTenant(String inviteId) async {
    setState(() => processingId = inviteId);

    final response = await ApiService.patch(
      "/admin/approve-tenant/$inviteId",
    );

    setState(() => processingId = null);

    if (response != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tenant Approved Successfully")),
      );
      fetchPendingTenants();
    }
  }

  Future<void> rejectTenant(String inviteId) async {
    setState(() => processingId = inviteId);

    final response = await ApiService.patch(
      "/admin/reject-tenant/$inviteId",
    );

    setState(() => processingId = null);

    if (response != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tenant Rejected")),
      );
      fetchPendingTenants();
    }
  }

  void showApproveDialog(String inviteId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Approve Tenant"),
        content: const Text("Are you sure you want to approve this tenant?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              approveTenant(inviteId);
            },
            child: const Text("Approve"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text("Pending Tenant Requests"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : pendingTenants.isEmpty
              ? const Center(
                  child: Text(
                    "No Pending Requests",
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: refreshData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: pendingTenants.length,
                    itemBuilder: (context, index) {
                      final tenant = pendingTenants[index];
                      final inviteId = tenant["_id"];

                      final isProcessing = processingId == inviteId;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: AppColors.primary,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    tenant["name"] ?? "",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text("Flat: ${tenant["flatNo"]}"),
                            Text("Mobile: ${tenant["mobile"]}"),
                            Text("Email: ${tenant["email"]}"),
                            const SizedBox(height: 8),
                            Text(
                              "Requested on: ${tenant["createdAt"]?.substring(0, 10)}",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 16),

                            /// 🔥 ACTION BUTTONS
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    onPressed: isProcessing
                                        ? null
                                        : () => showApproveDialog(inviteId),
                                    child: isProcessing
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text("Approve"),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: isProcessing
                                        ? null
                                        : () => rejectTenant(inviteId),
                                    child: const Text("Reject"),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
