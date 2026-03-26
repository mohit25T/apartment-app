import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../core/api/api_service.dart';
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
  Future<void> loadPreview() async {
    setState(() => loading = true);

    final res =
        await ApiService.get("/subscription/preview?plan=$selectedPlan");

    if (res != null) {
      setState(() {
        preview = res;
        isUpgrade = res["isUpgrade"] ?? false; // 🔥 IMPORTANT
        loading = false;
      });
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
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: loading
          ? const Center(child: WalkingLoader(size: 60))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      isUpgrade ? "Upgrade Plan" : "Premium Plan",
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    centerTitle: true,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // 🔥 SHOW EXTRA FLATS IF UPGRADE
                        if (isUpgrade) ...[
                          Text(
                            "New Flats Detected: ${preview?["extraFlats"] ?? 0}",
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

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