import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/walking_loader.dart';

class GenerateMaintenanceScreen extends StatefulWidget {
  const GenerateMaintenanceScreen({super.key});

  @override
  State<GenerateMaintenanceScreen> createState() =>
      _GenerateMaintenanceScreenState();
}

class _GenerateMaintenanceScreenState
    extends State<GenerateMaintenanceScreen> {
  final TextEditingController monthController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController dueDateController = TextEditingController();

  bool loading = false;

  Future<void> generateBills() async {
    if (monthController.text.isEmpty ||
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

    setState(() => loading = true);

    final response = await ApiService.post(
      "/maintenance/generate",
      {
        "month": monthController.text,
        "amount": amountController.text,
        "dueDate": dueDateController.text,
      },
    );

    setState(() => loading = false);

    if (response["message"] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response["message"])),
      );

      monthController.clear();
      amountController.clear();
      dueDateController.clear();
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

              // Month Field
              TextField(
                controller: monthController,
                decoration: const InputDecoration(
                  labelText: "Month (e.g. March 2026)",
                  prefixIcon: Icon(Icons.calendar_month),
                ),
              ),

              const SizedBox(height: 20),

              // Amount Field
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Amount",
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
              ),

              const SizedBox(height: 20),

              // Due Date Field
              TextField(
                controller: dueDateController,
                decoration: const InputDecoration(
                  labelText: "Due Date (YYYY-MM-DD)",
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
