import 'package:flutter/material.dart';
import '../core/api/api_service.dart';

class NewVisitorScreen extends StatefulWidget {
  const NewVisitorScreen({super.key});

  @override
  State<NewVisitorScreen> createState() => _NewVisitorScreenState();
}

class _NewVisitorScreenState extends State<NewVisitorScreen> {
  bool loading = false;
  bool flatSelected = false;

  List flats = [];
  String? selectedFlat;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController purposeController = TextEditingController();
  final TextEditingController vehicleController = TextEditingController();

  /* ============================
      FETCH AVAILABLE FLATS
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
      CREATE VISITOR ENTRY
  ============================ */
  Future<void> submitVisitor() async {
    if (nameController.text.isEmpty ||
        mobileController.text.length != 10 ||
        purposeController.text.isEmpty ||
        selectedFlat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all required fields")),
      );
      return;
    }

    setState(() => loading = true);

    final response = await ApiService.post(
      "/visitors/create",
      {
        "personName": nameController.text.trim(),
        "personMobile": mobileController.text.trim(),
        "flatNo": selectedFlat,
        "purpose": purposeController.text.trim(),
        "vehicleNo": vehicleController.text.trim(),
        "entryType": "VISITOR",
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
        const SnackBar(content: Text("Visitor entry failed")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchFlats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Visitor Entry"),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : flatSelected
              ? visitorForm()
              : flatSelection(),
    );
  }

  /* ============================
        FLAT SELECTION UI
  ============================ */
  Widget flatSelection() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: flats.length,
      itemBuilder: (context, index) {
        final flat = flats[index];

        return Card(
          child: ListTile(
            title: Text(flat["flatNo"] ?? "Flat"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              setState(() {
                selectedFlat = flat["flatNo"];
                flatSelected = true;
              });
            },
          ),
        );
      },
    );
  }

  /* ============================
        VISITOR FORM UI
  ============================ */
  Widget visitorForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "Selected Flat: $selectedFlat",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: "Visitor Name",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: mobileController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: const InputDecoration(
              labelText: "Visitor Mobile",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: purposeController,
            decoration: const InputDecoration(
              labelText: "Purpose",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: vehicleController,
            decoration: const InputDecoration(
              labelText: "Vehicle Number (optional)",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: loading ? null : submitVisitor,
              child: const Text(
                "Create Visitor Entry",
                style: TextStyle(fontSize: 16),
              ),
            ),
          )
        ],
      ),
    );
  }
}
