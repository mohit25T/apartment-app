import 'package:flutter/material.dart';
import '../core/api/api_service.dart';

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
      appBar: AppBar(
        title: const Text("Society Visitor Logs"),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : visitors.isEmpty
              ? const Center(child: Text("No visitor records found"))
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
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Flat: ${v["flatNo"] ?? "N/A"}",
                            ),
                            Text(
                              "Type: ${v["entryType"] ?? "N/A"}",
                            ),
                            Text(
                              "Status: ${v["status"] ?? "N/A"}",
                            ),
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
