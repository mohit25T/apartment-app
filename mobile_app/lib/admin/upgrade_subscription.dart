import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/walking_loader.dart';

class UpgradeSubscriptionScreen extends StatefulWidget {
  const UpgradeSubscriptionScreen({super.key});

  @override
  State<UpgradeSubscriptionScreen> createState() =>
      _UpgradeSubscriptionScreenState();
}

class _UpgradeSubscriptionScreenState
    extends State<UpgradeSubscriptionScreen> {
  Map? preview;
  Map? currentSub;

  bool loading = true;

  String selectedPlan = "monthly";

  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentError);

    initData();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ===============================
  // INIT DATA
  // ===============================
  Future<void> initData() async {
    setState(() => loading = true);

    final sub = await ApiService.get("/subscription/current");

    if (sub != null) {
      currentSub = sub;
      selectedPlan = sub["plan"] ?? "monthly";
    }

    await loadPreview();

    setState(() => loading = false);
  }

  // ===============================
  // 🔥 PREVIEW (FIXED)
  // ===============================
  Future<void> loadPreview() async {
    final res = await ApiService.get(
      "/subscription/preview?plan=$selectedPlan",
    );

    print("PREVIEW => $res");

    if (res != null && mounted) {
      setState(() {
        preview = res;
      });
    }
  }

  // ===============================
  // CREATE ORDER
  // ===============================
  Future<void> createOrder() async {
    final res = await ApiService.post(
      "/subscription/upgrade-order",
      {
        "plan": selectedPlan,
      },
    );

    if (res != null && res["order"] != null) {
      openRazorpay(res["order"]);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create order")),
      );
    }
  }

  // ===============================
  // RAZORPAY
  // ===============================
  void openRazorpay(Map order) {
    var options = {
      'key': 'rzp_test_SSLQR9ipXUzrd3',
      'amount': order["amount"],
      'currency': 'INR',
      'name': 'Apartment App',
      'description': 'Upgrade Subscription',
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
  // SUCCESS
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
        const SnackBar(content: Text("Subscription Upgraded 🎉")),
      );

      Navigator.pop(context);
    }
  }

  void handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${response.message}")),
    );
  }

  // ===============================
  // 🎨 UI COMPONENTS (UNIFIED)
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
                      color:
                          (accentColor ?? AppColors.primary).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon,
                        size: 20, color: accentColor ?? AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleMedium?.color,
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

  Widget _buildDetailRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: 15,
              color: valueColor ?? Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
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
              color: isSelected
                  ? AppColors.primary
                  : Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanToggle() {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withOpacity(0.05),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: loading
          ? const Center(child: WalkingLoader(size: 80))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 180,
                  pinned: true,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    title: const Text(
                      "Upgrade Plan",
                      style: TextStyle(
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
                            right: -20,
                            top: -20,
                            child: CircleAvatar(
                              radius: 100,
                              backgroundColor: Colors.white.withOpacity(0.05),
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
                        // 🔥 CURRENT PLAN CARD
                        _buildInfoCard(
                          title: "Current Status",
                          icon: Icons.auto_awesome_outlined,
                          children: [
                            _buildDetailRow(
                              "Active Plan",
                              currentSub?["plan"]?.toString().toUpperCase() ??
                                  "N/A",
                              valueColor: AppColors.primary,
                            ),
                            _buildDetailRow(
                              "Subscribed Units",
                              "${preview?["allowedFlats"] ?? 0} Units",
                            ),
                          ],
                        ),

                        // 📈 UPGRADE DETAILS
                        _buildInfoCard(
                          title: "Subscription Changes",
                          icon: Icons.trending_up_rounded,
                          accentColor: Colors.orange,
                          children: [
                            _buildDetailRow(
                              "Total Units in Society",
                              "${preview?["totalFlatsInDB"] ?? 0} Units",
                            ),
                            if ((preview?["extraFlats"] ?? 0) > 0)
                              _buildDetailRow(
                                "New Units Found",
                                "+${preview?["extraFlats"] ?? 0} Units",
                                valueColor: Colors.red,
                                isBold: true,
                              ),
                          ],
                        ),

                        // 💰 BILLING SUMMARY
                        _buildInfoCard(
                          title: "Billing Summary",
                          icon: Icons.receipt_long_outlined,
                          accentColor: Colors.green,
                          children: [
                            _buildDetailRow(
                              "Selected Cycle",
                              selectedPlan.toUpperCase(),
                            ),
                            _buildDetailRow(
                              "Unit Price",
                              "₹${preview?["pricePerFlat"] ?? 0}",
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(),
                            ),
                            _buildDetailRow(
                              "New Total",
                              "₹${preview?["totalAmount"] ?? 0}",
                              isBold: true,
                              valueColor: Theme.of(context).primaryColor,
                            ),
                          ],
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomSheet: loading
          ? null
          : Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: createOrder,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bolt, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Pay ₹${preview?["totalAmount"] ?? 0} & Upgrade",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}