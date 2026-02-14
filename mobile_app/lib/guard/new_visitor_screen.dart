import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/walking_loader.dart';

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
          backgroundColor: AppColors.error,
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
        SnackBar(
          content: Text(response["message"]),
          backgroundColor: Colors.green,
        ),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("New Visitor Entry"),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: WalkingLoader(size: 60))
          : flatSelected
              ? visitorForm()
              : flatSelection(),
    );
  }

  /* ============================
        FLAT SELECTION UI
  ============================ */
  Widget flatSelection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Select Destination Flat",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: flats.length,
            itemBuilder: (context, index) {
              final flat = flats[index];
              final flatNo = flat["flatNo"] ?? "N/A";

              return InkWell(
                onTap: () {
                  setState(() {
                    selectedFlat = flatNo;
                    flatSelected = true;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      "$flatNo",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /* ============================
        VISITOR FORM UI
  ============================ */
  Widget visitorForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => flatSelected = false),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Visiting Flat",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        "$selectedFlat",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.edit, color: AppColors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Visitor Details",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(nameController, "Visitor Name", Icons.person),
          const SizedBox(height: 16),
          _buildTextField(mobileController, "Visitor Mobile", Icons.phone, isPhone: true),
          const SizedBox(height: 16),
          _buildTextField(purposeController, "Purpose", Icons.assignment),
          const SizedBox(height: 16),
          _buildTextField(vehicleController, "Vehicle Number (Optional)", Icons.directions_car),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: loading ? null : submitVisitor,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "Create Visitor Entry",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPhone = false}) {
    return TextField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      maxLength: isPhone ? 10 : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        counterText: "",
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
