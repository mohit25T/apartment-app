import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'dart:convert';

import '../core/api/api_service.dart';
import '../core/storage/cache_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/walking_loader.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  Map? preview;
  bool loading = true;

  String selectedPlan = "monthly";

  bool isUpgrade = false;

  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentError);

    loadPreview();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ===============================
  // 🔍 Load Preview
  // ===============================
  // ===============================
  // 🔍 Load Preview
  // ===============================
  Future<void> loadPreview() async {
    // 1. Optimistic Cache Load
    try {
      final cachedPreview = await CacheService.getData("subscription_preview");
      if (cachedPreview != null && mounted) {
        setState(() {
          preview = cachedPreview;
          isUpgrade = cachedPreview["isUpgrade"] ?? false;
          loading = false;
        });
      }
    } catch (_) {}

    try {
      final res = await ApiService.get("/subscription/preview?plan=$selectedPlan");

      if (res != null) {
        final String cachedStr = jsonEncode(preview ?? {});
        final String freshStr = jsonEncode(res);

        if (cachedStr == freshStr && !loading) return;

        await CacheService.saveData("subscription_preview", res);

        if (mounted) {
          setState(() {
            preview = res;
            isUpgrade = res["isUpgrade"] ?? false;
            loading = false;
          });
        }
      } else {
        if (mounted) setState(() => loading = false);
      }
    } catch (e) {
      if (mounted && loading == true) setState(() => loading = false);
    }
  }

  // ===============================
  // 💳 Create Order
  // ===============================
  Future<void> createOrder() async {
    final res = await ApiService.post(
      "/subscription/create-order",
      {
        "plan": selectedPlan,
      },
    );

    if (res != null && res["order"] != null) {
      isUpgrade = res["isUpgrade"] ?? false;
      openRazorpay(res["order"]);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create order")),
      );
    }
  }

  // ===============================
  // 🔥 Open Razorpay
  // ===============================
  void openRazorpay(Map order) {
    var options = {
      'key': 'rzp_test_SSLQR9ipXUzrd3',
      'amount': order["amount"],
      'currency': 'INR',
      'name': 'Apartment App',
      'description':
          isUpgrade ? 'Upgrade Subscription' : 'Society Subscription',
      'order_id': order["id"],
      'timeout': 300,
      'prefill': {
        'contact': '9876543210',
        'email': 'test@razorpay.com',
      },
      'theme': {'color': '#1976D2'}
    };

    _razorpay.open(options);
  }

  // ===============================
  // ✅ Payment Success
  // ===============================
  void handlePaymentSuccess(PaymentSuccessResponse response) async {
    final res = await ApiService.post(
      "/subscription/verify-payment",
      {
        "razorpay_order_id": response.orderId,
        "razorpay_payment_id": response.paymentId,
        "razorpay_signature": response.signature,
        "plan": selectedPlan,
      },
    );

    if (res != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUpgrade
                ? "Subscription Upgraded 🎉"
                : "Subscription Activated 🎉",
          ),
        ),
      );

      Navigator.pop(context);
    }
  }

  // ===============================
  // ❌ Payment Error
  // ===============================
  void handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${response.message}")),
    );
  }

  // ===============================
  // 🎨 UI COMPONENTS
  // ===============================
  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
    IconData? icon,
    Color? accentColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (accentColor ?? AppColors.primary).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 20, color: accentColor ?? AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: 15,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanToggle() {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _buildToggleItem("monthly", "Monthly"),
          _buildToggleItem("yearly", "Yearly"),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String plan, String label) {
    final bool isSelected = selectedPlan == plan;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedPlan = plan;
            loading = true;
          });
          loadPreview();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: loading
          ? const Center(child: WalkingLoader(size: 80))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    title: Text(
                      isUpgrade ? "Upgrade Plan" : "Premium Plan",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, Color(0xFF1565C0)],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -30,
                            top: -30,
                            child: CircleAvatar(
                              radius: 120,
                              backgroundColor: Colors.white.withOpacity(0.05),
                            ),
                          ),
                          Center(
                            child: Icon(
                              Icons.star_rounded,
                              size: 80,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔄 PLAN SELECTOR
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            "Select Subscription Plan",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // 📊 SUMMARY
                        Text("Flats: ${preview?["totalFlats"] ?? 0}"),
                        Text("Price/Flat: ₹${preview?["pricePerFlat"] ?? 0}"),
                        Text("Total: ₹${preview?["totalAmount"] ?? 0}"),

                        const SizedBox(height: 40),

                        // 💳 BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: createOrder,
                            child: Text(
                              isUpgrade ? "Upgrade Now" : "Subscribe Now",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}