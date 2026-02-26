import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/walking_loader.dart';

class SocietyVisitorLogsScreen extends StatefulWidget {
  const SocietyVisitorLogsScreen({super.key});

  @override
  State<SocietyVisitorLogsScreen> createState() =>
      _SocietyVisitorLogsScreenState();
}

class _SocietyVisitorLogsScreenState extends State<SocietyVisitorLogsScreen> {
  bool loading = true;
  bool isLoadingMore = false;
  bool hasMore = true;

  int currentPage = 1;
  final int limit = 20;

  List visitors = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadLogs();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        hasMore) {
      loadMoreLogs();
    }
  }

  Future<void> loadLogs() async {
    setState(() {
      loading = true;
      currentPage = 1;
      hasMore = true;
    });

    final response =
        await ApiService.get("/admin/Society?page=$currentPage&limit=$limit");

    if (response != null && response["success"] == true) {
      visitors = response["visitors"] ?? [];
      hasMore = response["hasMore"] ?? false;
    }

    setState(() => loading = false);
  }

  Future<void> loadMoreLogs() async {
    if (!hasMore) return;

    setState(() => isLoadingMore = true);
    currentPage++;

    final response =
        await ApiService.get("/admin/Society?page=$currentPage&limit=$limit");

    if (response != null && response["success"] == true) {
      visitors.addAll(response["visitors"] ?? []);
      hasMore = response["hasMore"] ?? false;
    }

    setState(() => isLoadingMore = false);
  }

  void showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Society Visitor Logs"),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: WalkingLoader(size: 60))
          : visitors.isEmpty
              ? const Center(child: Text("No visitor records found"))
              : ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: visitors.length + (hasMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                    final String status = v["status"] ?? "N/A";
                    final String? photoUrl = v["visitorPhoto"];

                    Color statusColor = Colors.grey;
                    if (status == "APPROVED") {
                      statusColor = Colors.green;
                    } else if (status == "REJECTED") {
                      statusColor = Colors.red;
                    } else if (status == "PENDING") {
                      statusColor = Colors.orange;
                    }

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: photoUrl != null
                                ? () => showFullImage(photoUrl)
                                : null,
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.1),
                              child: photoUrl != null
                                  ? ClipOval(
                                      child: Image.network(
                                        photoUrl,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, progress) {
                                          if (progress == null) return child;
                                          return const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          );
                                        },
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.person),
                                      ),
                                    )
                                  : const Icon(Icons.person,
                                      color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  v["personName"] ?? "Visitor",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.home,
                                        size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Flat: ${v["flatNo"] ?? "N/A"}",
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.assignment_ind,
                                        size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      v["entryType"] ?? "Guest",
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatDate(v["createdAt"]),
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade500),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
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

  String _formatDate(String? date) {
    if (date == null) return "";
    final d = DateTime.parse(date);
    return "${d.day}/${d.month}/${d.year}";
  }
}
