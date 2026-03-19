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
        await ApiService.get("/subscriptions/preview?plan=$selectedPlan");

    print("PREVIEW DATA: $res"); // 🔥 debug

    if (res != null) {
      setState(() {
        preview = res;
        loading = false;
      });
    }
  }

  // ===============================
  // 💳 Create Order
  // ===============================
  Future<void> createOrder() async {
    final res = await ApiService.post(
      "/subscriptions/order",
      {"plan": selectedPlan},
    );

    print("ORDER RESPONSE: $res"); // 🔥 debug

    if (res != null && res["order"] != null) {
      openRazorpay(res["order"]);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create order")),
      );
    }
  }

  // ===============================
  // 🔥 Open Razorpay (FIXED)
  // ===============================
  void openRazorpay(Map order) {
    print("OPENING RAZORPAY: $order"); // 🔥 debug

    var options = {
      'key': 'rzp_test_SSLQR9ipXUzrd3', // 🔥 PUT YOUR REAL KEY HERE
      'amount': order["amount"], // must be in paise
      'currency': 'INR',

      // 🔥 IMPORTANT DETAILS
      'name': 'Apartment App',
      'description': 'Society Subscription',
      'order_id': order["id"],

      // 🔥 THIS FIXES MOST ERRORS
      'timeout': 300,

      // 🔥 NEVER KEEP EMPTY
      'prefill': {
        'contact': '9876543210',
        'email': 'test@razorpay.com',
      },

      // 🔥 Helps avoid failure
      // 'external': {
      //   'wallets': ['paytm', 'phonepe', 'googlepay']
      // },

      // 🎨 Theme
      'theme': {
        'color': '#1976D2',
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print("RAZORPAY OPEN ERROR: $e");
    }
  }

  // ===============================
  // ✅ Payment Success
  // ===============================
  void handlePaymentSuccess(PaymentSuccessResponse response) async {
    print("PAYMENT SUCCESS: ${response.paymentId}");

    final res = await ApiService.post(
      "/subscriptions/verify",
      {
        "razorpay_order_id": response.orderId,
        "razorpay_payment_id": response.paymentId,
        "razorpay_signature": response.signature,
        "plan": selectedPlan,
      },
    );

    if (res != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Subscription Activated 🎉")),
      );

      Navigator.pop(context);
    }
  }

  // ===============================
  // ❌ Payment Error
  // ===============================
  void handlePaymentError(PaymentFailureResponse response) {
    print("PAYMENT ERROR: ${response.message}");

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
      appBar: AppBar(
        title: const Text("Subscription"),
        backgroundColor: AppColors.primary,
      ),
      body: loading
          ? const Center(child: WalkingLoader(size: 60))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [

                  // 📊 Info Card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            "${preview?["totalFlats"] ?? 0} Flats",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "₹${preview?["pricePerFlat"] ?? 0} / flat",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Total: ₹${preview?["totalAmount"] ?? 0}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🔄 Plan Selector
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text("Monthly"),
                          selected: selectedPlan == "monthly",
                          onSelected: (_) {
                            setState(() => selectedPlan = "monthly");
                            loadPreview();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text("Yearly"),
                          selected: selectedPlan == "yearly",
                          onSelected: (_) {
                            setState(() => selectedPlan = "yearly");
                            loadPreview();
                          },
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // 💳 Subscribe Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: createOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        "Subscribe Now",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}