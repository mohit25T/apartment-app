import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/walking_loader.dart';

class ResidentPendingVisitorsScreen extends StatefulWidget {
  const ResidentPendingVisitorsScreen({super.key});

  @override
  State<ResidentPendingVisitorsScreen> createState() =>
      _ResidentPendingVisitorsScreenState();
}

class _ResidentPendingVisitorsScreenState
    extends State<ResidentPendingVisitorsScreen> {
  bool loading = true;
  bool actionLoading = false;
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

    try {
      final response = await ApiService.get("/visitors?status=PENDING");

      if (response != null &&
          response["success"] == true &&
          response["data"] != null) {
        setState(() {
          visitors = response["data"];
        });
      } else {
        visitors = [];
      }
    } catch (e) {
      debugPrint("FETCH VISITORS ERROR: $e");
    }

    setState(() => loading = false);
  }

  /* ============================
        APPROVE VISITOR
  ============================ */
  Future<void> approveVisitor(String id) async {
    if (actionLoading) return;

    setState(() => actionLoading = true);

    final res = await ApiService.put("/visitors/approve/$id", {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res["message"] ?? "Approved"),
        backgroundColor: Colors.green,
      ),
    );

    await fetchVisitors();
    setState(() => actionLoading = false);
  }

  /* ============================
        REJECT VISITOR
  ============================ */
  Future<void> rejectVisitor(String id) async {
    if (actionLoading) return;

    setState(() => actionLoading = true);

    final res = await ApiService.put("/visitors/reject/$id", {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res["message"] ?? "Rejected"),
        backgroundColor: AppColors.error,
      ),
    );

    await fetchVisitors();
    setState(() => actionLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Pending Visitors"),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: WalkingLoader(size: 60))
          : visitors.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 64, color: Colors.grey.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        "No pending visitors",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: visitors.length,
                  itemBuilder: (context, index) {
                    final v = visitors[index];
                    final photoUrl = v["visitorPhoto"]; // 👈 IMAGE FIELD

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor:
                                      AppColors.secondary.withOpacity(0.1),
                                  backgroundImage: photoUrl != null
                                      ? NetworkImage(photoUrl)
                                      : null,
                                  child: photoUrl == null
                                      ? const Icon(Icons.person,
                                          color: AppColors.secondary)
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        v["personName"] ?? "Visitor",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (v["purpose"] != null)
                                        Text(
                                          "Purpose: ${v["purpose"]}",
                                          style: TextStyle(
                                              color: Colors.grey.shade600),
                                        ),
                                      if (v["entryType"] == "DELIVERY")
                                        Text(
                                          "Delivery: ${v["deliveryCompany"] ?? ""}",
                                          style: const TextStyle(
                                            color: Colors.orangeAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => rejectVisitor(v["_id"]),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(16),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withOpacity(0.1),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(16),
                                      ),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        "REJECT",
                                        style: TextStyle(
                                          color: AppColors.error,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                  width: 1,
                                  height: 50,
                                  color: Colors.grey.shade200),
                              Expanded(
                                child: InkWell(
                                  onTap: () => approveVisitor(v["_id"]),
                                  borderRadius: const BorderRadius.only(
                                    bottomRight: Radius.circular(16),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: const BorderRadius.only(
                                        bottomRight: Radius.circular(16),
                                      ),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        "APPROVE",
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
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
}
