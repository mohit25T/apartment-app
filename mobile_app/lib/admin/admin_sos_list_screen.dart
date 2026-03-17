import 'package:flutter/material.dart';
import '../core/api/api_service.dart';

class AdminSOSListScreen extends StatefulWidget {
  const AdminSOSListScreen({super.key});

  @override
  State<AdminSOSListScreen> createState() => _AdminSOSListScreenState();
}

class _AdminSOSListScreenState extends State<AdminSOSListScreen> {

  List sosList = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchSOS();
  }

  Future<void> fetchSOS() async {
    try {
      final response = await ApiService.get("/sos/history");

      if (response["success"] == true) {
        setState(() {
          sosList = response["data"] ?? [];
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() {
      loading = false;
    });
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "active":
        return Colors.red;
      case "responding":
        return Colors.orange;
      case "resolved":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("SOS Alerts"),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : sosList.isEmpty
              ? const Center(child: Text("No SOS Alerts"))
              : ListView.builder(
                  itemCount: sosList.length,
                  itemBuilder: (context, index) {

                    final sos = sosList[index];

                    return Card(
                      margin: const EdgeInsets.all(12),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "🚨 ${sos["emergencyType"].toUpperCase()}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: getStatusColor(sos["status"]),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    sos["status"].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              ],
                            ),

                            const SizedBox(height: 10),

                            Text("Resident: ${sos["userId"]["name"]}"),
                            Text("Wing: ${sos["wing"]}"),
                            Text("Flat: ${sos["flatNo"]}"),

                            const SizedBox(height: 6),

                            Text(
                              "Time: ${DateTime.parse(sos["createdAt"]).toLocal()}",
                              style: const TextStyle(color: Colors.grey),
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