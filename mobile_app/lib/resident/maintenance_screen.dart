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
  List bills = [];

  @override
  void initState() {
    super.initState();
    fetchBills();
  }

  Future<void> fetchBills() async {
    setState(() => loading = true);

    final response = await ApiService.get("/maintenance/my-bills");

    setState(() => loading = false);

    if (response is List) {
      setState(() {
        bills = response;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response["message"] ?? "Failed to load bills"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> payBill(String id) async {
    setState(() => loading = true);

    final response = await ApiService.put("/maintenance/pay/$id", {});

    setState(() => loading = false);

    if (response["message"] != null) {
      await fetchBills(); // refresh list

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response["message"])),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response["message"] ?? "Payment failed"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Color getStatusColor(String status) {
    if (status == "Paid") return Colors.green;
    if (status == "Pending") return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Maintenance Bills"),
      ),
      body: loading
          ? const Center(
              child: WalkingLoader(
                size: 60,
                color: AppColors.primary,
              ),
            )
          : bills.isEmpty
              ? const Center(
                  child: Text("No bills available"),
                )
              : RefreshIndicator(
                  onRefresh: fetchBills,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: bills.length,
                    itemBuilder: (context, index) {
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
                            // Month
                            Text(
                              bill["month"],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Amount
                            Text("Amount: ₹${bill["amount"]}"),

                            const SizedBox(height: 8),

                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: getStatusColor(bill["status"])
                                    .withOpacity(0.1),
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

                            const SizedBox(height: 12),

                            // Pay Button
                            bill["status"] == "Pending"
                                ? SizedBox(
                                    width: double.infinity,
                                    height: 45,
                                    child: ElevatedButton(
                                      onPressed: loading
                                          ? null
                                          : () => payBill(bill["_id"]),
                                      child: const Text("Pay Now"),
                                    ),
                                  )
                                : const SizedBox(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
