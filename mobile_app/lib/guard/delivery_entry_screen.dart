import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  List wings = [];
  List flats = [];

  String? selectedWing;
  String? selectedFlat;

  bool wingSelected = false;

  String? selectedCompany;
  String? parcelType;

  XFile? deliveryImage;
  final ImagePicker _picker = ImagePicker();

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
        FETCH WINGS
  ============================ */

  Future<void> fetchFlats() async {
    setState(() => loading = true);

    final response = await ApiService.get("/visitors/flats");

    if (response != null && response["type"] == "WINGS") {
      wings = response["data"];
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response?["message"] ?? "Failed to load wings"),
          backgroundColor: AppColors.error,
        ),
      );
    }

    setState(() => loading = false);
  }

  /* ============================
        FETCH FLATS OF WING
  ============================ */

  Future<void> fetchWingFlats() async {

    final response =
        await ApiService.get("/visitors/flats?wing=$selectedWing");

    if (response != null && response["type"] == "FLATS") {
      flats = response["data"];
    }

    setState(() {});
  }

  /* ============================
        PICK IMAGE
  ============================ */

  Future<void> pickImage() async {
    final XFile? picked =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);

    if (picked != null) {
      setState(() {
        deliveryImage = picked;
      });
    }
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

    if (deliveryImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Capture delivery person photo")),
      );
      return;
    }

    setState(() => loading = true);

    final selectedFlatData =
        flats.firstWhere((f) => f["flatNo"] == selectedFlat);

    final response = await ApiService.multipart(
      "/visitors/create",
      {
        "personName": selectedCompany,
        "personMobile": mobileController.text.trim(),
        "wing": selectedFlatData["wing"],
        "flatNo": selectedFlat,
        "entryType": "DELIVERY",
        "deliveryCompany": selectedCompany,
        "parcelType": parcelType,
      },
      xFiles: [deliveryImage!],
      fileFieldName: "visitorPhoto",
    );

    setState(() => loading = false);

    if (response != null && response["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Delivery entry created successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response?["message"] ?? "Delivery entry failed"),
        ),
      );
    }
  }

  @override
  void dispose() {
    mobileController.dispose();
    super.dispose();
  }

  /* ============================
        UI
  ============================ */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Delivery Entry"),
        backgroundColor: AppColors.primary,
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

                  /// WING SELECTION
                  if (!wingSelected)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: wings.length,
                      itemBuilder: (context, index) {

                        final wing = wings[index]["wing"];

                        return InkWell(
                          onTap: () {
                            selectedWing = wing;
                            wingSelected = true;
                            fetchWingFlats();
                            setState(() {});
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                wing,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  /// FLAT SELECTION
                  if (wingSelected && selectedFlat == null)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: flats.length,
                      itemBuilder: (context, index) {

                        final flat =
                            "${flats[index]["wing"]}-${flats[index]["flatNo"]}";

                        return InkWell(
                          onTap: () {
                            selectedFlat = flats[index]["flatNo"];
                            setState(() {});
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                flat,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  /// DELIVERY FORM
                  if (selectedFlat != null) ...[

                    const SizedBox(height: 24),

                    GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade200,
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: deliveryImage == null
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt,
                                        size: 40, color: AppColors.primary),
                                    SizedBox(height: 8),
                                    Text("Capture Delivery Photo"),
                                  ],
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(deliveryImage!.path),
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildDropdown(
                      value: selectedCompany,
                      hint: "Delivery Company",
                      items: companies
                          .map((c) =>
                              DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => selectedCompany = val),
                      icon: Icons.local_shipping,
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: mobileController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: InputDecoration(
                        labelText: "Delivery Person Mobile",
                        prefixIcon: const Icon(Icons.phone_android,
                            color: AppColors.primary),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                        counterText: "",
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      decoration: InputDecoration(
                        labelText: "Parcel Type (optional)",
                        prefixIcon: const Icon(Icons.inventory_2,
                            color: AppColors.primary),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
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
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: loading
                            ? const WalkingLoader(
                                size: 24,
                                color: Colors.white,
                              )
                            : const Text(
                                "Create Delivery Entry",
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    )
                  ]
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
