import 'package:flutter/material.dart';
import '../core/api/api_service.dart';

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
        SnackBar(content: Text(response["message"])),
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
      appBar: AppBar(
        title: const Text("Delivery Entry"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// FLAT SELECT
            DropdownButtonFormField(
              value: selectedFlat,
              hint: const Text("Select Flat"),
              items: flats.map<DropdownMenuItem<String>>((f) {
                return DropdownMenuItem(
                  value: f["flatNo"],
                  child: Text("${f["flatNo"]}"),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedFlat = val;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            /// DELIVERY COMPANY
            DropdownButtonFormField(
              value: selectedCompany,
              hint: const Text("Delivery Company"),
              items: companies
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                setState(() {
                  selectedCompany = val;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            /// DELIVERY PERSON MOBILE
            TextField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: "Delivery Person Mobile",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            /// PARCEL TYPE
            TextField(
              decoration: const InputDecoration(
                labelText: "Parcel Type (optional)",
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                parcelType = val;
              },
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : createDelivery,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Create Delivery Entry",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
