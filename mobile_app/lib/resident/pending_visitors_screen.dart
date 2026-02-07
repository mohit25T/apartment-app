import 'package:flutter/material.dart';
import '../core/api/api_service.dart';

class ResidentPendingVisitorsScreen extends StatefulWidget {
  const ResidentPendingVisitorsScreen({super.key});

  @override
  State<ResidentPendingVisitorsScreen> createState() =>
      _ResidentPendingVisitorsScreenState();
}

class _ResidentPendingVisitorsScreenState
    extends State<ResidentPendingVisitorsScreen> {
  bool loading = true;
  List visitors = [];

  @override
  void initState() {
    super.initState();
    fetchVisitors();
  }

  /* ============================
        FETCH VISITORS
  ============================ */
  Future<void> fetchVisitors() async {
    setState(() => loading = true);

    final response = await ApiService.get("/visitors");

    if (response is List) {
      setState(() {
        visitors = response.where((v) => v["status"] == "PENDING").toList();
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  /* ============================
        APPROVE VISITOR
  ============================ */
  Future<void> approveVisitor(String id) async {
    final res = await ApiService.put(
      "/visitors/approve/$id",
      {},
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res["message"] ?? "Approved")),
    );

    fetchVisitors();
  }

  /* ============================
        REJECT VISITOR
  ============================ */
  Future<void> rejectVisitor(String id) async {
    final res = await ApiService.put(
      "/visitors/reject/$id",
      {},
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res["message"] ?? "Rejected")),
    );

    fetchVisitors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pending Visitors"),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : visitors.isEmpty
              ? const Center(child: Text("No pending visitors"))
              : ListView.builder(
                  itemCount: visitors.length,
                  itemBuilder: (context, index) {
                    final v = visitors[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(v["personName"] ?? "Visitor"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Flat: ${v["flatNo"]}"),
                            if (v["entryType"] == "DELIVERY")
                              Text("Delivery: ${v["deliveryCompany"] ?? ""}"),
                            if (v["purpose"] != null)
                              Text("Purpose: ${v["purpose"]}"),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => rejectVisitor(v["_id"]),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.check, color: Colors.green),
                              onPressed: () => approveVisitor(v["_id"]),
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
