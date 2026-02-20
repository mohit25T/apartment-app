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
  final TextEditingController dueDateController = TextEditingController();

  bool loading = false;

  String? selectedMonth;
  String selectedYear = DateTime.now().year.toString();

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

  /* ============================
        DATE PICKER
  ============================ */
  Future<void> pickDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      dueDateController.text = DateFormat('dd-MM-yyyy').format(picked);
    }
  }

  /* ============================
        GENERATE BILLS
  ============================ */
  Future<void> generateBills() async {
    if (selectedMonth == null ||
        amountController.text.isEmpty ||
        dueDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final monthValue = "$selectedMonth $selectedYear";

    setState(() => loading = true);

    final response = await ApiService.post(
      "/maintenance/generate",
      {
        "month": monthValue,
        "amount": amountController.text,
        "dueDate": dueDateController.text,
      },
    );

    setState(() => loading = false);

    if (response != null && response["message"] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response["message"])),
      );

      setState(() {
        selectedMonth = null;
        amountController.clear();
        dueDateController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response["message"] ?? "Failed to generate bills"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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

              /* ================= MONTH DROPDOWN ================= */
              DropdownButtonFormField<String>(
                value: selectedMonth,
                decoration: const InputDecoration(
                  labelText: "Select Month",
                  prefixIcon: Icon(Icons.calendar_month),
                ),
                items: months.map((month) {
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

              /* ================= YEAR DROPDOWN ================= */
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
                  });
                },
              ),
              const SizedBox(height: 20),

              /* ================= AMOUNT ================= */
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Amount",
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
              ),
              const SizedBox(height: 20),

              /* ================= DATE PICKER ================= */
              TextField(
                controller: dueDateController,
                readOnly: true,
                onTap: pickDueDate,
                decoration: const InputDecoration(
                  labelText: "Select Due Date",
                  prefixIcon: Icon(Icons.event),
                ),
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
