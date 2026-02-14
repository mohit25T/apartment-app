import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/walking_loader.dart';

class DeliveryEntryScreen extends StatefulWidget {
  const DeliveryEntryScreen({super.key});

  @override
  State<DeliveryEntryScreen> createState() => _DeliveryEntryScreenState();
}

class _DeliveryEntryScreenState extends State<DeliveryEntryScreen> {
  bool loading = false;

  List flats = [];
  String? selectedFlat;

  String? selectedCompany;
  String? parcelType;

  final TextEditingController mobileController = TextEditingController();

  final List<String> companies = [
    "Amazon",
    "Flipkart",
    "Swiggy",
    "Zomato",
    "Blinkit",
    "Dunzo",
    "Other"
  ];

  @override
  void initState() {
    super.initState();
    fetchFlats();
  }

  /* ============================
        FETCH FLATS
  ============================ */
  Future<void> fetchFlats() async {
    setState(() => loading = true);

    final response = await ApiService.get("/visitors/flats");

    if (response is List) {
      setState(() {
        flats = response;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response["message"] ?? "Failed to load flats"),
          backgroundColor: AppColors.error,
        ),
      );
    }

    setState(() => loading = false);
  }

  /* ============================
        CREATE DELIVERY ENTRY
  ============================ */
  Future<void> createDelivery() async {
    if (selectedFlat == null || selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select flat and company")),
      );
      return;
    }

    if (mobileController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid mobile number")),
      );
      return;
    }

    setState(() => loading = true);

    final response = await ApiService.post(
      "/visitors/create",
      {
        "personName": selectedCompany,
        "personMobile": mobileController.text.trim(),
        "flatNo": selectedFlat,
        "entryType": "DELIVERY",
        "deliveryCompany": selectedCompany,
        "parcelType": parcelType,
      },
    );

    setState(() => loading = false);

    if (response != null && response["message"] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response["message"]),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Delivery entry failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Delivery Entry"),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: WalkingLoader(size: 60))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Log Delivery",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  /// FLAT SELECT
                  _buildDropdown(
                    value: selectedFlat,
                    hint: "Select Flat",
                    items: flats.map<DropdownMenuItem<String>>((f) {
                      return DropdownMenuItem(
                        value: f["flatNo"],
                        child: Text("${f["flatNo"]}"),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => selectedFlat = val),
                    icon: Icons.apartment,
                  ),

                  const SizedBox(height: 20),

                  /// DELIVERY COMPANY
                  _buildDropdown(
                    value: selectedCompany,
                    hint: "Delivery Company",
                    items: companies
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedCompany = val),
                    icon: Icons.local_shipping,
                  ),

                  const SizedBox(height: 20),

                  /// DELIVERY PERSON MOBILE
                  TextField(
                    controller: mobileController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: InputDecoration(
                      labelText: "Delivery Person Mobile",
                      prefixIcon: const Icon(Icons.phone_android, color: AppColors.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                      counterText: "",
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// PARCEL TYPE
                  TextField(
                    decoration: InputDecoration(
                      labelText: "Parcel Type (optional)",
                      prefixIcon: const Icon(Icons.inventory_2, color: AppColors.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (val) {
                      parcelType = val;
                    },
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading ? null : createDelivery,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: WalkingLoader(size: 24, color: Colors.white),
                            )
                          : const Text(
                              "Create Delivery Entry",
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Row(
            children: [
              Icon(icon, color: Colors.grey.shade600, size: 22),
              const SizedBox(width: 12),
              Text(hint),
            ],
          ),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
