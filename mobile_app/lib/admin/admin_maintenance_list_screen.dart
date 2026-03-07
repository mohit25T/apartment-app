import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/walking_loader.dart';
import 'package:intl/intl.dart';

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
  List filteredBills = [];

  String selectedFilter = "ALL";

  Map<String, dynamic>? dashboardStats;

  @override
  void initState() {
    super.initState();
    fetchBills();
    fetchDashboardStats();
  }

  /* ===========================
        FETCH DASHBOARD
  =========================== */

  Future<void> fetchDashboardStats() async {
    final response = await ApiService.get("/maintenance/dashboard-stats");

    if (response != null) {
      setState(() {
        dashboardStats = response;
      });
    }
  }

  /* ===========================
        FETCH BILLS
  =========================== */

  Future<void> fetchBills() async {
    setState(() => loading = true);

    final response = await ApiService.get("/maintenance/all");

    setState(() => loading = false);

    if (response != null && response["data"] != null) {
      setState(() {
        bills = response["data"];
        filteredBills = bills;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response?["message"] ?? "Failed to load bills"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /* ===========================
        FILTER FUNCTION
  =========================== */

  void applyFilter(String filter) {
    selectedFilter = filter;

    if (filter == "ALL") {
      filteredBills = bills;
    } else if (filter == "PAID") {
      filteredBills = bills.where((b) => b["status"] == "Paid").toList();
    } else if (filter == "PENDING") {
      filteredBills = bills.where((b) => b["status"] == "Pending").toList();
    } else if (filter == "OVERDUE") {
      filteredBills = bills.where((b) => b["status"] == "Overdue").toList();
    } else if (filter == "YEARLY") {
      filteredBills = bills.where((b) => b["paymentType"] == "YEARLY").toList();
    }

    setState(() {});
  }

  /* ===========================
        MARK SINGLE MONTH
  =========================== */

  Future<void> markAsPaid(String id) async {
    String selectedMode = "CASH";
    final TextEditingController noteController = TextEditingController();

    final confirm = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select Payment Method",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedMode,
                    items: const [
                      DropdownMenuItem(value: "CASH", child: Text("Cash")),
                      DropdownMenuItem(value: "UPI", child: Text("UPI")),
                      DropdownMenuItem(value: "CHEQUE", child: Text("Cheque")),
                      DropdownMenuItem(value: "ONLINE", child: Text("Online")),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        selectedMode = value!;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: "Payment Mode",
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: "Payment Note (Optional)",
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Confirm Payment"),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (confirm != true) return;

    setState(() => loading = true);

    final response = await ApiService.put(
      "/maintenance/pay/$id",
      {
        "paymentMode": selectedMode,
        "paymentNote": noteController.text.trim(),
      },
    );

    setState(() => loading = false);

    if (response != null && response["message"] != null) {
      await fetchBills();
      await fetchDashboardStats();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response["message"])),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response?["message"] ?? "Failed to update"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /* ===========================
        MARK FULL YEAR
  =========================== */

  Future<void> markFullYearPaid(
      String residentId, String year, String residentName) async {
    String selectedMode = "CASH";
    final TextEditingController noteController = TextEditingController();

    final confirm = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Full Year Payment - $residentName ($year)",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedMode,
                    items: const [
                      DropdownMenuItem(value: "CASH", child: Text("Cash")),
                      DropdownMenuItem(value: "UPI", child: Text("UPI")),
                      DropdownMenuItem(value: "CHEQUE", child: Text("Cheque")),
                      DropdownMenuItem(value: "ONLINE", child: Text("Online")),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        selectedMode = value!;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: "Payment Mode",
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: "Payment Note (Optional)",
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Confirm Full Year Payment"),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (confirm != true) return;

    setState(() => loading = true);

    final response = await ApiService.post(
      "/maintenance/pay-full-year",
      {
        "residentId": residentId,
        "year": year,
        "paymentMode": selectedMode,
        "paymentNote": noteController.text.trim(),
      },
    );

    setState(() => loading = false);

    if (response != null && response["success"] == true) {
      await fetchBills();
      await fetchDashboardStats();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Full year marked as paid")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response?["message"] ?? "Failed to update"),
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

  bool isDueInFiveDays(String? dueDateStr, String status) {
    if (dueDateStr == null || status != "Pending") return false;

    final dueDate = DateTime.tryParse(dueDateStr);
    if (dueDate == null) return false;

    final today = DateTime.now();
    final difference = dueDate.difference(today).inDays;

    return difference >= 0 && difference <= 5;
  }

  String extractYear(String monthString) {
    final parts = monthString.split(" ");
    return parts.length > 1 ? parts.last : DateTime.now().year.toString();
  }

  Widget statCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(title),
        ],
      ),
    );
  }

  Widget dashboardCards() {
    if (dashboardStats == null) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        children: [
          statCard("Flats", dashboardStats!["totalFlats"].toString()),
          statCard("Paid", dashboardStats!["paidThisMonth"].toString()),
          statCard("Pending", dashboardStats!["pendingPayments"].toString()),
          statCard("Overdue", dashboardStats!["overduePayments"].toString()),
        ],
      ),
    );
  }

  Widget filterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          filterChip("ALL"),
          filterChip("PAID"),
          filterChip("PENDING"),
          filterChip("OVERDUE"),
          filterChip("YEARLY"),
        ],
      ),
    );
  }

  Widget filterChip(String value) {
    final isSelected = selectedFilter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(value),
        selected: isSelected,
        onSelected: (_) {
          applyFilter(value);
        },
      ),
    );
  }

  String formatDate(String date) {
    return DateFormat("dd-MM-yyyy").format(DateTime.parse(date));
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
          : filteredBills.isEmpty
              ? const Center(child: Text("No maintenance records found"))
              : RefreshIndicator(
                  onRefresh: fetchBills,
                  child: ListView(
                    children: [
                      dashboardCards(),
                      filterBar(),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredBills.length,
                        itemBuilder: (context, index) {
                          final bill = filteredBills[index];

                          final status = bill["status"] ?? "Pending";
                          final dueDate = bill["dueDate"];
                          final paymentMode = bill["paymentMode"];

                          final residentId = bill["residentId"]?["_id"] ?? "";
                          final residentName =
                              bill["residentId"]?["name"] ?? "Resident";

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
                                  residentName,
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
                                if (dueDate != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      "Due: ${formatDate(dueDate)}",
                                      style: TextStyle(
                                        color: showReminder
                                            ? Colors.red
                                            : Colors.grey[700],
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
                                    color:
                                        getStatusColor(status).withOpacity(0.1),
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
                                const SizedBox(height: 12),
                                status == "Pending"
                                    ? Column(
                                        children: [
                                          SizedBox(
                                            width: double.infinity,
                                            height: 40,
                                            child: ElevatedButton(
                                              onPressed: loading
                                                  ? null
                                                  : () =>
                                                      markAsPaid(bill["_id"]),
                                              child: const Text("Mark as Paid"),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 40,
                                            child: OutlinedButton(
                                              onPressed: loading
                                                  ? null
                                                  : () => markFullYearPaid(
                                                        residentId,
                                                        extractYear(
                                                            bill["month"]),
                                                        residentName,
                                                      ),
                                              child: const Text(
                                                  "Mark Full Year Paid"),
                                            ),
                                          ),
                                        ],
                                      )
                                    : const SizedBox(),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }
}
