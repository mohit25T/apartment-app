import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/walking_loader.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  bool loading = false;
  bool isLoadingMore = false;
  bool hasMore = true;

  int currentPage = 1;
  final int limit = 20;

  List bills = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchBills();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        hasMore) {
      loadMoreBills();
    }
  }

  Future<void> fetchBills() async {
    setState(() {
      loading = true;
      currentPage = 1;
      hasMore = true;
    });

    final response = await ApiService.get(
        "/maintenance/my-bills?page=$currentPage&limit=$limit");

    if (response != null && response["data"] != null) {
      setState(() {
        bills = response["data"];
        hasMore = response["hasMore"] ?? false;
        loading = false;
      });
    } else {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response?["message"] ?? "Failed to load bills"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> loadMoreBills() async {
    if (!hasMore) return;

    setState(() => isLoadingMore = true);

    currentPage++;

    final response = await ApiService.get(
        "/maintenance/my-bills?page=$currentPage&limit=$limit");

    if (response != null && response["data"] != null) {
      setState(() {
        bills.addAll(response["data"]);
        hasMore = response["hasMore"] ?? false;
        isLoadingMore = false;
      });
    } else {
      setState(() => isLoadingMore = false);
    }
  }

  Color getStatusColor(String status) {
    if (status == "Paid") return Colors.green;
    if (status == "Pending") return Colors.orange;
    return Colors.red;
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
      appBar: AppBar(title: const Text("Maintenance Bills")),
      body: loading
          ? const Center(
              child: WalkingLoader(size: 60, color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: fetchBills,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: bills.length + (hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == bills.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: WalkingLoader(size: 40),
                      ),
                    );
                  }

                  final bill = bills[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bill["month"],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text("Amount: ₹${bill["amount"]}"),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                getStatusColor(bill["status"]).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            bill["status"],
                            style: TextStyle(
                              color: getStatusColor(bill["status"]),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
