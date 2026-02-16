import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/walking_loader.dart';

class AdminMaintenanceListScreen extends StatefulWidget {
  const AdminMaintenanceListScreen({super.key});

  @override
  State<AdminMaintenanceListScreen> createState() =>
      _AdminMaintenanceListScreenState();
}

class _AdminMaintenanceListScreenState
    extends State<AdminMaintenanceListScreen> {
  bool loading = false;
  List bills = [];

  @override
  void initState() {
    super.initState();
    fetchBills();
  }

  Future<void> fetchBills() async {
    setState(() => loading = true);

    final response = await ApiService.get("/maintenance/all");

    setState(() => loading = false);

    if (response is List) {
      setState(() => bills = response);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response["message"] ?? "Failed to load bills"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> markAsPaid(String id) async {
    setState(() => loading = true);

    final response = await ApiService.put("/maintenance/pay/$id", {});

    setState(() => loading = false);

    if (response["message"] != null) {
      await fetchBills();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response["message"])),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response["message"] ?? "Failed to update"),
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
      appBar: AppBar(title: const Text("All Maintenance Bills")),
      body: loading
          ? const Center(
              child: WalkingLoader(
                size: 60,
                color: AppColors.primary,
              ),
            )
          : bills.isEmpty
              ? const Center(
                  child: Text("No maintenance records found"),
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
                            Text(
                              bill["residentId"]?["name"] ?? "Resident",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                                "Flat: ${bill["residentId"]?["flatNo"] ?? bill["flatNumber"]}"),
                            const SizedBox(height: 6),
                            Text("Month: ${bill["month"]}"),
                            const SizedBox(height: 6),
                            Text("Amount: ₹${bill["amount"]}"),
                            const SizedBox(height: 10),

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

                            // Mark as Paid Button
                            bill["status"] == "Pending"
                                ? SizedBox(
                                    width: double.infinity,
                                    height: 40,
                                    child: ElevatedButton(
                                      onPressed: loading
                                          ? null
                                          : () => markAsPaid(bill["_id"]),
                                      child: const Text("Mark as Paid"),
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
