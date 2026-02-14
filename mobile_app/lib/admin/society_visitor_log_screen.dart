import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/walking_loader.dart';

class SocietyVisitorLogsScreen extends StatefulWidget {
  const SocietyVisitorLogsScreen({super.key});

  @override
  State<SocietyVisitorLogsScreen> createState() =>
      _SocietyVisitorLogsScreenState();
}

class _SocietyVisitorLogsScreenState extends State<SocietyVisitorLogsScreen> {
  bool loading = true;
  List visitors = [];

  @override
  void initState() {
    super.initState();
    loadLogs();
  }

  Future<void> loadLogs() async {
    final response = await ApiService.get("/admin/Society");

    if (response != null && response["success"] == true) {
      setState(() {
        visitors = response["visitors"] ?? [];
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Society Visitor Logs"),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: WalkingLoader(size: 60))
          : visitors.isEmpty
              ? const Center(child: Text("No visitor records found"))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: visitors.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final v = visitors[index];
                    final String status = v["status"] ?? "N/A";
                    Color statusColor = Colors.grey;
                    if (status == "APPROVED") statusColor = Colors.green;
                    else if (status == "REJECTED") statusColor = Colors.red;
                    else if (status == "PENDING") statusColor = Colors.orange;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person, color: AppColors.primary),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  v["personName"] ?? "Visitor",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.home, size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Flat: ${v["flatNo"] ?? "N/A"}",
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.assignment_ind, size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      v["entryType"] ?? "Guest",
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatDate(v["createdAt"]),
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return "";
    final d = DateTime.parse(date);
    return "${d.day}/${d.month}/${d.year}";
  }
}
