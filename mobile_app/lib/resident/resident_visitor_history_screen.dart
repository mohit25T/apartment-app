import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/walking_loader.dart';

class ResidentVisitorHistoryScreen extends StatefulWidget {
  const ResidentVisitorHistoryScreen({super.key});

  @override
  State<ResidentVisitorHistoryScreen> createState() =>
      _ResidentVisitorHistoryScreenState();
}

class _ResidentVisitorHistoryScreenState
    extends State<ResidentVisitorHistoryScreen> {
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
    loadVisitorHistory();
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

  Future<void> loadVisitorHistory() async {
    setState(() {
      loading = true;
      currentPage = 1;
      hasMore = true;
    });

    final response = await ApiService.get(
        "/users/resident-visitor-history?page=$currentPage&limit=$limit");

    if (response != null && response["success"] == true) {
      visitors = response["visitors"] ?? [];
      hasMore = response["hasMore"] ?? false;
    }

    setState(() => loading = false);
  }

  Future<void> loadMoreVisitors() async {
    if (!hasMore) return;

    setState(() => isLoadingMore = true);

    currentPage++;

    final response = await ApiService.get(
        "/users/resident-visitor-history?page=$currentPage&limit=$limit");

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
        title: const Text("Visitor History"),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: WalkingLoader(size: 60))
          : visitors.isEmpty
              ? const Center(child: Text("No visitor history found"))
              : ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: visitors.length + (hasMore ? 1 : 0),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
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
                    final status = v["status"] ?? "N/A";
                    final photoUrl = v["visitorPhoto"];

                    Color statusColor = Colors.grey;
                    if (status == "APPROVED") {
                      statusColor = Colors.green;
                    } else if (status == "REJECTED") {
                      statusColor = Colors.red;
                    } else if (status == "PENDING") {
                      statusColor = Colors.orange;
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: GestureDetector(
                          onTap: photoUrl != null
                              ? () => showFullImage(photoUrl)
                              : null,
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: photoUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      photoUrl,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(Icons.person),
                                    ),
                                  )
                                : const Icon(Icons.person,
                                    color: AppColors.primary),
                          ),
                        ),
                        title: Text(
                          v["personName"] ?? "Visitor",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            _buildInfoRow(Icons.phone_android,
                                v["personMobile"] ?? "N/A"),
                            const SizedBox(height: 4),
                            _buildInfoRow(
                                Icons.assignment, v["purpose"] ?? "N/A"),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          _formatDate(v["createdAt"]),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
        ),
      ],
    );
  }

  String _formatDate(String? date) {
    if (date == null) return "";
    final d = DateTime.parse(date);
    return "${d.day}/${d.month}/${d.year}";
  }
}
