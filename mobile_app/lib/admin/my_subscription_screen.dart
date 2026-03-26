import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/walking_loader.dart';

class MySubscriptionScreen extends StatefulWidget {
  const MySubscriptionScreen({super.key});

  @override
  State<MySubscriptionScreen> createState() => _MySubscriptionScreenState();
}

class _MySubscriptionScreenState extends State<MySubscriptionScreen> {
  bool loading = true;
  Map? subscriptionData;

  @override
  void initState() {
    super.initState();
    loadSubscription();
  }

  Future<void> loadSubscription() async {
    try {
      final res = await ApiService.get("/subscription/me");

      // 🔥 DEBUG (remove later)

      if (mounted) {
        setState(() {
          subscriptionData = res;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("My Subscription"),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: WalkingLoader(size: 60))
          : subscriptionData == null
              ? const Center(
                  child: Text(
                    "No active subscription found.",
                    style: TextStyle(
                        fontSize: 16, color: AppColors.textSecondary),
                  ),
                )
              : _buildSubscriptionDetails(),
    );
  }

  Widget _buildSubscriptionDetails() {
    // 🔥 HANDLE BOTH ROOT + NESTED STRUCTURE
    final raw = subscriptionData ?? {};
    final nested = raw["subscription"] ?? {};

    final status = raw["status"] ?? nested["status"] ?? "ACTIVE";
    final plan = raw["plan"] ?? nested["plan"] ?? "Monthly";
    final totalAmount = raw["amount"] ?? nested["amount"] ?? 0;

    final startDateValue =
        raw["startDate"] ?? nested["startDate"];
    final endDateValue =
        raw["endDate"] ?? nested["endDate"];

    // 📅 Format Dates
    String startDateStr = "N/A";
    String endDateStr = "N/A";

    if (startDateValue != null) {
      try {
        DateTime parsed = DateTime.parse(startDateValue);
        startDateStr =
            "${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}";
      } catch (_) {
        startDateStr = startDateValue.toString();
      }
    }

    if (endDateValue != null) {
      try {
        DateTime parsed = DateTime.parse(endDateValue);
        endDateStr =
            "${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}";
      } catch (_) {
        endDateStr = endDateValue.toString();
      }
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🌟 HEADER CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.workspace_premium,
                          size: 70, color: Colors.amberAccent),
                      const SizedBox(height: 20),
                      Text(
                        "$plan Plan".toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // STATUS CHIP
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: status.toString().toUpperCase() == "ACTIVE"
                              ? Colors.greenAccent.withOpacity(0.2)
                              : Colors.redAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color:
                                status.toString().toUpperCase() == "ACTIVE"
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                          ),
                        ),
                        child: Text(
                          status.toString().toUpperCase(),
                          style: TextStyle(
                            color:
                                status.toString().toUpperCase() == "ACTIVE"
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                const Text(
                  "Subscription Details",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 20),

                // 📦 DETAILS CARD
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildDetailRow(
                          "Amount Paid",
                          "₹$totalAmount",
                          Icons.payments_outlined),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(),
                      ),

                      _buildDetailRow(
                          "Start Date",
                          startDateStr,
                          Icons.calendar_today_outlined),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(),
                      ),

                      _buildDetailRow(
                          "Next Billing Date",
                          endDateStr,
                          Icons.event_repeat_outlined),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // 🔐 FOOTER
                Center(
                  child: Column(
                    children: [
                      const Icon(Icons.security_rounded,
                          color: Colors.green, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        "Your society is actively protected with premium features",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String title, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}