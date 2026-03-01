import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/widgets/walking_loader.dart';
import '../core/theme/app_theme.dart';

class ComplaintMyScreen extends StatefulWidget {
  const ComplaintMyScreen({super.key});

  @override
  State<ComplaintMyScreen> createState() => _ComplaintMyScreenState();
}

class _ComplaintMyScreenState extends State<ComplaintMyScreen> {
  bool loading = true;
  List complaints = [];

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    setState(() => loading = true);

    final response = await ApiService.get("/complaints/my");

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

  Widget buildImages(List images) {
    if (images.isEmpty) return const SizedBox();

    return SizedBox(
      height: 100,
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
                width: 100,
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
      appBar: AppBar(title: const Text("My Complaints")),
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
                      child: Text(
                        "No complaints found",
                        style: TextStyle(fontSize: 16),
                      ),
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
                                const SizedBox(height: 8),
                                Text(
                                  complaint["description"] ?? "",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                buildImages(complaint["images"] ?? []),
                                if (complaint["adminResponse"] != null &&
                                    complaint["adminResponse"]
                                        .toString()
                                        .isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(top: 12),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "Admin Response:\n${complaint["adminResponse"]}",
                                      style: const TextStyle(fontSize: 13),
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
