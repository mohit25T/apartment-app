import 'package:flutter/material.dart';
import '../core/api/api_service.dart';

class ResidentVisitorsScreen extends StatefulWidget {
  const ResidentVisitorsScreen({super.key});

  @override
  State<ResidentVisitorsScreen> createState() =>
      _ResidentVisitorsScreenState();
}

class _ResidentVisitorsScreenState extends State<ResidentVisitorsScreen> {
  List visitors = [];
  bool loading = true;

  Future<void> loadVisitors() async {
    final response = await ApiService.get("/visitors");

    if (response is List) {
      setState(() {
        visitors = response;
        loading = false;
      });
    }
  }

  // ✅ GUARD ENTER
  Future<void> enter(String id) async {
    await ApiService.put("/visitors/enter/$id", {});
    loadVisitors();
  }

  // ✅ GUARD EXIT
  Future<void> exitVisitor(String id) async {
    await ApiService.put("/visitors/exit/$id", {});
    loadVisitors();
  }

  @override
  void initState() {
    super.initState();
    loadVisitors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Visitor Entries")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: visitors.length,
              itemBuilder: (context, index) {
                final v = visitors[index];
                final status = v["status"];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(v["personName"] ?? ""),
                    subtitle: Text("Flat: ${v["flatNo"]}"),

                    trailing:
                        // ✅ APPROVED → ENTER BUTTON
                        status == "APPROVED"
                            ? ElevatedButton(
                                onPressed: () => enter(v["_id"]),
                                child: const Text("ENTER"),
                              )

                            // ✅ ENTERED → EXIT BUTTON
                            : status == "ENTERED"
                                ? ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () =>
                                        exitVisitor(v["_id"]),
                                    child: const Text("EXIT"),
                                  )

                                // ✅ FINAL STATES
                                : status == "EXITED"
                                    ? const Text(
                                        "EXITED",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : status == "REJECTED"
                                        ? const Text(
                                            "REJECTED",
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : const Text(
                                            "PENDING",
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                  ),
                );
              },
            ),
    );
  }
}
