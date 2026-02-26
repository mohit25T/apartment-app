import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/walking_loader.dart';

class ResidentVisitorsScreen extends StatefulWidget {
  const ResidentVisitorsScreen({super.key});

  @override
  State<ResidentVisitorsScreen> createState() => _ResidentVisitorsScreenState();
}

class _ResidentVisitorsScreenState extends State<ResidentVisitorsScreen> {
  List visitors = [];
  bool loading = true;
  bool isLoadingMore = false;
  bool hasMore = true;

  int currentPage = 1;
  final int limit = 20;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadVisitors();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        hasMore) {
      loadMoreVisitors();
    }
  }

  Future<void> loadVisitors() async {
    setState(() {
      loading = true;
      currentPage = 1;
      hasMore = true;
    });

    final response =
        await ApiService.get("/visitors?page=$currentPage&limit=$limit");

    if (response != null && response["data"] != null) {
      setState(() {
        visitors = response["data"];
        hasMore = response["hasMore"] ?? false;
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  Future<void> loadMoreVisitors() async {
    if (!hasMore) return;

    setState(() => isLoadingMore = true);

    currentPage++;

    final response =
        await ApiService.get("/visitors?page=$currentPage&limit=$limit");

    if (response != null && response["data"] != null) {
      setState(() {
        visitors.addAll(response["data"]);
        hasMore = response["hasMore"] ?? false;
        isLoadingMore = false;
      });
    } else {
      setState(() => isLoadingMore = false);
    }
  }

  Future<void> enter(String id) async {
    await ApiService.put("/visitors/enter/$id", {});
    loadVisitors();
  }

  Future<void> exitVisitor(String id) async {
    await ApiService.put("/visitors/exit/$id", {});
    loadVisitors();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Color _statusColor(String? status) {
    switch (status) {
      case "APPROVED":
        return Colors.blue;
      case "ENTERED":
        return Colors.green;
      case "EXITED":
        return Colors.grey;
      case "REJECTED":
        return AppColors.error;
      default:
        return Colors.black54;
    }
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
            onPressed: loadVisitors,
          ),
        ],
      ),
      body: loading
          ? const Center(child: WalkingLoader(size: 60))
          : visitors.isEmpty
              ? const Center(child: Text("No visitors found"))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: visitors.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == visitors.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: WalkingLoader(size: 40),
                        ),
                      );
                    }

                    final v = visitors[index];
                    final status = v["status"];
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
                          ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundColor:
                                  _statusColor(status).withOpacity(0.1),
                              backgroundImage: photoUrl != null
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: photoUrl == null
                                  ? Icon(
                                      Icons.person,
                                      color: _statusColor(status),
                                    )
                                  : null,
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color:
                                        _statusColor(status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status ?? "UNKNOWN",
                                    style: TextStyle(
                                      color: _statusColor(status),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text("MARK ENTER", style: TextStyle(color: Colors.white)),
      );
    } else if (status == "ENTERED") {
      return ElevatedButton(
        onPressed: () => exitVisitor(id),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
