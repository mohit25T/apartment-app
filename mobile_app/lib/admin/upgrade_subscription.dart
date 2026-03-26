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

    final sub = await ApiService.get("/subscription/me");

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
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upgrade Subscription")),
      body: loading
          ? const Center(child: WalkingLoader())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // 🔥 CURRENT PLAN
                  Text(
                    "Current Plan: ${currentSub?["plan"]}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Allowed Flats: ${preview?["allowedFlats"] ?? 0}",
                  ),

                  const SizedBox(height: 20),

                  // 🔄 PLAN SELECT
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => selectedPlan = "monthly");
                            loadPreview();
                          },
                          child: const Text("Monthly"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => selectedPlan = "yearly");
                            loadPreview();
                          },
                          child: const Text("Yearly"),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 🔥 AUTO CALCULATED INFO
                  Text("Total Flats: ${preview?["totalFlatsInDB"] ?? 0}"),
                  Text("Subscribed Flats: ${preview?["allowedFlats"] ?? 0}"),

                  const SizedBox(height: 10),

                  Text(
                    "New Flats: ${preview?["extraFlats"] ?? 0}",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 💰 BILLING
                  Text("Flats to Pay: ${preview?["totalFlats"] ?? 0}"),
                  Text("Price/Flat: ₹${preview?["pricePerFlat"] ?? 0}"),
                  Text("Total: ₹${preview?["totalAmount"] ?? 0}"),

                  const Spacer(),

                  // 💳 BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: createOrder,
                      child: const Text("Upgrade Now"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}