import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/services/sos_alarm_service.dart';

class GuardSOSAlertScreen extends StatefulWidget {
  const GuardSOSAlertScreen({super.key});

  @override
  State<GuardSOSAlertScreen> createState() => _GuardSOSAlertScreenState();
}

class _GuardSOSAlertScreenState extends State<GuardSOSAlertScreen> {
  List sosList = [];
  bool loading = true;

  Future<void> fetchSOS() async {
    setState(() {
      loading = true;
    });

    try {
      final response = await ApiService.get("/sos/active");

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

  Future<void> respondSOS(String id) async {
    try {
      final response = await ApiService.patch("/sos/respond/$id");

      if (response["success"] == true) {

        // 🔊 STOP SOS SIREN
        await SOSAlarmService.stopAlarm();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Guard responding to SOS")),
        );

        fetchSOS();
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> resolveSOS(String id) async {
    try {
      final response = await ApiService.patch("/sos/resolve/$id");

      if (response["success"] == true) {

        // 🔊 STOP SOS SIREN
        await SOSAlarmService.stopAlarm();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("SOS Resolved")),
        );

        fetchSOS();
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSOS();
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
              ? const Center(
                  child: Text("No Active SOS Alerts"),
                )
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
                            Text(
                              "🚨 ${sos["emergencyType"].toUpperCase()} ALERT",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text("Resident: ${sos["userId"]["name"]}"),
                            Text("Wing: ${sos["wing"]}"),
                            Text("Flat: ${sos["flatNo"]}"),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () =>
                                      respondSOS(sos["_id"]),
                                  child: const Text("Respond"),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  onPressed: () =>
                                      resolveSOS(sos["_id"]),
                                  child: const Text("Resolve"),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}