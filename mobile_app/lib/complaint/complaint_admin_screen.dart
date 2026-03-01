import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/widgets/walking_loader.dart';
import '../core/theme/app_theme.dart';

class ComplaintAdminScreen extends StatefulWidget {
  const ComplaintAdminScreen({super.key});

  @override
  State<ComplaintAdminScreen> createState() => _ComplaintAdminScreenState();
}

class _ComplaintAdminScreenState extends State<ComplaintAdminScreen> {
  bool loading = true;
  List complaints = [];

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    setState(() => loading = true);

    final response = await ApiService.get("/complaints/all");

    if (response != null && response["success"] == true) {
      complaints = response["data"];
    }

    setState(() => loading = false);
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "OPEN":
        return Colors.orange;
      case "IN_PROGRESS":
        return Colors.blue;
      case "RESOLVED":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> updateStatus(
    String id,
    String newStatus,
    String? adminResponse,
  ) async {
    final response = await ApiService.patch(
      "/complaints/update/$id",
      body: {"status": newStatus, "adminResponse": adminResponse},
    );

    if (response != null && response["success"] == true) {
      fetchComplaints();
    }
  }

  void showUpdateDialog(Map complaint) {
    String selectedStatus = complaint["status"];
    final responseController =
        TextEditingController(text: complaint["adminResponse"] ?? "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Update Complaint"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField(
              value: selectedStatus,
              items: const [
                DropdownMenuItem(value: "OPEN", child: Text("Open")),
                DropdownMenuItem(
                    value: "IN_PROGRESS", child: Text("In Progress")),
                DropdownMenuItem(value: "RESOLVED", child: Text("Resolved")),
              ],
              onChanged: (val) => selectedStatus = val!,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: responseController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Admin Response",
              ),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              updateStatus(
                complaint["_id"],
                selectedStatus,
                responseController.text,
              );
            },
            child: const Text("Update"),
          )
        ],
      ),
    );
  }

  Widget buildImages(List images) {
    if (images.isEmpty) return const SizedBox();

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                images[index],
                width: 90,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Manage Complaints"),
      ),
      body: loading
          ? const Center(
              child: WalkingLoader(
                size: 60,
                color: AppColors.primary,
              ),
            )
          : RefreshIndicator(
              onRefresh: fetchComplaints,
              child: complaints.isEmpty
                  ? const Center(
                      child: Text("No complaints"),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: complaints.length,
                      itemBuilder: (context, index) {
                        final complaint = complaints[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        complaint["title"],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            getStatusColor(complaint["status"])
                                                .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        complaint["status"],
                                        style: TextStyle(
                                          color: getStatusColor(
                                              complaint["status"]),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text("Flat: ${complaint["flatNo"]}"),
                                const SizedBox(height: 6),
                                Text(
                                  complaint["description"] ?? "",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                buildImages(complaint["images"] ?? []),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        showUpdateDialog(complaint),
                                    child: const Text("Update"),
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
