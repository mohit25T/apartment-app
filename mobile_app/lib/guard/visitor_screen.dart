import 'package:flutter/material.dart';
import 'dart:convert';
import '../core/storage/cache_service.dart';
import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/walking_loader.dart';
import '../core/services/socket_service.dart';
import 'dart:async';

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
  StreamSubscription? _socketSub;

  static const String cacheKey = "resident_visitors_cache";

  @override
  void initState() {
    super.initState();
    loadCachedVisitors();
    loadVisitors();
    _scrollController.addListener(_scrollListener);

    // 🔌 Socket Update
    _socketSub = SocketService().visitorStream.listen((_) {
      loadVisitors();
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        hasMore) {
      loadMoreVisitors();
    }
  }

  /* ===============================
     LOAD CACHED VISITORS
  =============================== */

  Future<void> loadCachedVisitors() async {
    final cached = await CacheService.getData(cacheKey);
    if (cached != null && mounted) {
      setState(() {
        visitors = cached;
        loading = false;
      });
    }
  }

  /* ===============================
     SAVE CACHE
  =============================== */

  Future<void> saveVisitorsCache(List data) async {
    await CacheService.saveData(cacheKey, data);
  }

  /* ===============================
     LOAD VISITORS FROM API
  =============================== */

  Future<void> loadVisitors() async {
    if (visitors.isEmpty) {
      setState(() {
        loading = true;
        currentPage = 1;
        hasMore = true;
      });
    } else {
      currentPage = 1;
      hasMore = true;
    }

    final response =
        await ApiService.get("/visitors?page=$currentPage&limit=$limit");

    if (response != null && response["data"] != null) {
      final newVisitors = response["data"];

      final String cachedStr = jsonEncode(visitors);
      final String freshStr = jsonEncode(newVisitors);

      if (cachedStr == freshStr && !loading) {
         hasMore = response["hasMore"] ?? false;
         return; // Array perfectly matches, skip rebuild
      }

      if (mounted) {
        setState(() {
          visitors = newVisitors;
          hasMore = response["hasMore"] ?? false;
          loading = false;
        });
      }

      await saveVisitorsCache(visitors);
    } else {
      if (mounted) setState(() => loading = false);
    }
  }

  /* ===============================
     LOAD MORE VISITORS
  =============================== */

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

      await saveVisitorsCache(visitors);
    } else {
      setState(() => isLoadingMore = false);
    }
  }

  /* ===============================
     ENTER VISITOR
  =============================== */

  Future<void> enter(String id) async {
    await ApiService.put("/visitors/enter/$id", {});
    loadVisitors();
  }

  /* ===============================
     EXIT VISITOR
  =============================== */

  Future<void> exitVisitor(String id) async {
    await ApiService.put("/visitors/exit/$id", {});
    loadVisitors();
  }

  @override
  void dispose() {
    _socketSub?.cancel();
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
        return Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    }
  }

  String getFlatDisplay(Map v) {
    final wing = v["wing"];
    final flat = v["flatNo"];

    if (wing != null && flat != null) {
      return "$wing-$flat";
    }

    return flat ?? "-";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Visitor Entries"),
        centerTitle: true,
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
                    final photoUrl = v["visitorPhoto"];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
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
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                            subtitle: Text(
                              "Flat: ${getFlatDisplay(v)}",
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
