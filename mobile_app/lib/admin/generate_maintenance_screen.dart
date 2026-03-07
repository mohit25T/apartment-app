import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/walking_loader.dart';

class GenerateMaintenanceScreen extends StatefulWidget {
  const GenerateMaintenanceScreen({super.key});

  @override
  State<GenerateMaintenanceScreen> createState() =>
      _GenerateMaintenanceScreenState();
}

class _GenerateMaintenanceScreenState extends State<GenerateMaintenanceScreen> {
  final TextEditingController amountController = TextEditingController();

  bool loading = false;

  String? selectedMonth;
  String selectedYear = DateTime.now().year.toString();
  int? selectedDueDay;

  DateTime? selectedDueDate;

  final DateTime now = DateTime.now();

  final List<String> months = const [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];

  List<String> getValidMonths() {
    int currentYear = now.year;
    int selectedYearInt = int.parse(selectedYear);

    if (selectedYearInt == currentYear) {
      return months.sublist(now.month - 1);
    } else {
      return months;
    }
  }

  Future<void> generateBills() async {
    if (selectedMonth == null ||
        amountController.text.isEmpty ||
        selectedDueDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
          backgroundColor: AppColors.error,
        ),
      );

      return;
    }

    final amount = double.tryParse(amountController.text);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter valid amount"),
          backgroundColor: AppColors.error,
        ),
      );

      return;
    }

    int monthIndex = months.indexOf(selectedMonth!) + 1;
    int yearInt = int.parse(selectedYear);

    selectedDueDate = DateTime(yearInt, monthIndex, selectedDueDay!);

    final monthValue = "$selectedMonth $selectedYear";

    setState(() => loading = true);

    final response = await ApiService.post(
      "/maintenance/generate",
      {
        "month": monthValue,
        "amount": amount,
        "dueDate": selectedDueDate!.toIso8601String(),
      },
    );

    setState(() => loading = false);

    if (response != null && response["message"] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response["message"])),
      );

      setState(() {
        selectedMonth = null;
        selectedDueDay = null;
        amountController.clear();
        selectedDueDate = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response?["message"] ?? "Failed to generate bills"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget previewCard() {
    if (selectedMonth == null ||
        selectedDueDay == null ||
        amountController.text.isEmpty) {
      return const SizedBox();
    }

    int monthIndex = months.indexOf(selectedMonth!) + 1;
    int yearInt = int.parse(selectedYear);

    DateTime previewDate = DateTime(yearInt, monthIndex, selectedDueDay!);

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Bill Preview",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text("Month: $selectedMonth $selectedYear"),
          Text("Amount: ₹${amountController.text}"),
          Text(
            "Due Date: ${DateFormat('dd MMM yyyy').format(previewDate)}",
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final validMonths = getValidMonths();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Generate Maintenance"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Icon(
                Icons.receipt_long_rounded,
                size: 70,
                color: AppColors.primary,
              ),
              const SizedBox(height: 20),
              Text(
                "Generate Monthly Bills",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              previewCard(),
              DropdownButtonFormField<String>(
                value: selectedMonth,
                decoration: const InputDecoration(
                  labelText: "Select Month",
                  prefixIcon: Icon(Icons.calendar_month),
                ),
                items: validMonths.map((month) {
                  return DropdownMenuItem(
                    value: month,
                    child: Text(month),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedMonth = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedYear,
                decoration: const InputDecoration(
                  labelText: "Select Year",
                  prefixIcon: Icon(Icons.date_range),
                ),
                items: List.generate(10, (index) {
                  final year = (DateTime.now().year + index).toString();
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year),
                  );
                }),
                onChanged: (value) {
                  setState(() {
                    selectedYear = value!;
                    selectedMonth = null;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Amount",
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                onChanged: (_) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                value: selectedDueDay,
                decoration: const InputDecoration(
                  labelText: "Select Due Date (1-10)",
                  prefixIcon: Icon(Icons.event),
                ),
                items: List.generate(10, (index) {
                  int day = index + 1;
                  return DropdownMenuItem(
                    value: day,
                    child: Text(day.toString()),
                  );
                }),
                onChanged: (value) {
                  setState(() {
                    selectedDueDay = value;
                  });
                },
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: loading ? null : generateBills,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: loading
                      ? const WalkingLoader(
                          size: 40,
                          color: Colors.white,
                        )
                      : const Text("Generate Bills"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
