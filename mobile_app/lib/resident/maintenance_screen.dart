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

  bool isDueInFiveDays(String? dueDateStr, String status) {
    if (dueDateStr == null || status != "Pending") return false;

    final dueDate = DateTime.tryParse(dueDateStr);
    if (dueDate == null) return false;

    final today = DateTime.now();
    final difference = dueDate.difference(today).inDays;

    return difference >= 0 && difference <= 5;
  }

  int getTotalAmount() {
    int total = 0;
    for (var bill in bills) {
      total += (bill["amount"] ?? 0) as int;
    }
    return total;
  }

  int getPaidAmount() {
    int total = 0;
    for (var bill in bills) {
      if (bill["status"] == "Paid") {
        total += (bill["amount"] ?? 0) as int;
      }
    }
    return total;
  }

  int getPendingAmount() {
    int total = 0;
    for (var bill in bills) {
      if (bill["status"] != "Paid") {
        total += (bill["amount"] ?? 0) as int;
      }
    }
    return total;
  }

  Widget summaryCard() {
    if (bills.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Maintenance Summary",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text("₹${getTotalAmount()}",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const Text("Total"),
                ],
              ),
              Column(
                children: [
                  Text("₹${getPaidAmount()}",
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                  const Text("Paid"),
                ],
              ),
              Column(
                children: [
                  Text("₹${getPendingAmount()}",
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red)),
                  const Text("Pending"),
                ],
              ),
            ],
          )
        ],
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
                itemCount: bills.length + (hasMore ? 2 : 1),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return summaryCard();
                  }

                  if (index == bills.length + 1) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: WalkingLoader(size: 40),
                      ),
                    );
                  }

                  final bill = bills[index - 1];
                  final status = bill["status"] ?? "Pending";
                  final dueDate = bill["dueDate"];
                  final paidAt = bill["paidAt"];
                  final paymentMode = bill["paymentMode"];

                  final showReminder = isDueInFiveDays(dueDate, status);

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
                          bill["month"] ?? "",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Amount: ₹${bill["amount"]}",
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        if (dueDate != null)
                          Text(
                            "Due: ${DateTime.parse(dueDate).toLocal().toString().split(" ")[0]}",
                            style: TextStyle(
                              color:
                                  showReminder ? Colors.red : Colors.grey[700],
                            ),
                          ),
                        if (showReminder)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              "⚠ Due within 5 days",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        if (status == "Paid" && paidAt != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              "Paid on: ${DateTime.parse(paidAt).toLocal().toString().split(" ")[0]}",
                              style: const TextStyle(
                                color: Colors.green,
                              ),
                            ),
                          ),
                        if (status == "Paid" && paymentMode != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              "Mode: $paymentMode",
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: getStatusColor(status),
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
