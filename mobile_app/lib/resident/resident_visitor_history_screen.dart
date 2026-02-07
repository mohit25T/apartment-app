import 'package:flutter/material.dart';
import '../core/api/api_service.dart';

class ResidentVisitorHistoryScreen extends StatefulWidget {
  const ResidentVisitorHistoryScreen({super.key});

  @override
  State<ResidentVisitorHistoryScreen> createState() =>
      _ResidentVisitorHistoryScreenState();
}

class _ResidentVisitorHistoryScreenState
    extends State<ResidentVisitorHistoryScreen> {
  bool loading = true;
  List visitors = [];

  @override
  void initState() {
    super.initState();
    loadVisitorHistory();
  }

  Future<void> loadVisitorHistory() async {
    final response = await ApiService.get("/users/resident-visitor-history");

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
      appBar: AppBar(
        title: const Text("Visitor History"),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : visitors.isEmpty
              ? const Center(child: Text("No visitor history found"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: visitors.length,
                  itemBuilder: (context, index) {
                    final v = visitors[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(
                          v["personName"] ?? "Visitor",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text("Mobile: ${v["personMobile"] ?? "N/A"}"),
                            Text("Flat: ${v["flatNo"] ?? "N/A"}"),
                            Text("Purpose: ${v["purpose"] ?? "N/A"}"),
                            Text("Status: ${v["status"] ?? "N/A"}"),
                          ],
                        ),
                        trailing: Text(
                          _formatDate(v["createdAt"]),
                          style: const TextStyle(fontSize: 12),
                        ),
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
