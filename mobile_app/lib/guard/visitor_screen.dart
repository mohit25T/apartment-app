import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/walking_loader.dart';

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
    } else {
      setState(() => loading = false);
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Visitor Entries"),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => loading = true);
              loadVisitors();
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: WalkingLoader(size: 60))
          : visitors.isEmpty
              ? const Center(child: Text("No visitors found"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: visitors.length,
                  itemBuilder: (context, index) {
                    final v = visitors[index];
                    final status = v["status"];

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
                          ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.secondary.withOpacity(0.1),
                              child: const Icon(Icons.person, color: AppColors.secondary),
                            ),
                            title: Text(
                              v["personName"] ?? "Unknown",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              "Flat: ${v["flatNo"]}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status ?? "UNKNOWN",
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                _buildActionButton(status, v["_id"]),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildActionButton(String? status, String id) {
    if (status == "APPROVED") {
      return ElevatedButton(
        onPressed: () => enter(id),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        ),
        child: const Text("MARK ENTER", style: TextStyle(color: Colors.white)),
      );
    } else if (status == "ENTERED") {
      return ElevatedButton(
        onPressed: () => exitVisitor(id),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        ),
        child: const Text("MARK EXIT", style: TextStyle(color: Colors.white)),
      );
    } else if (status == "EXITED") {
      return const Icon(Icons.check_circle, color: Colors.grey);
    } else if (status == "REJECTED") {
      return const Icon(Icons.cancel, color: AppColors.error);
    } else {
      return const SizedBox.shrink();
    }
  }
}
