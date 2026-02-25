import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
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

  File? visitorImage;

  final ImagePicker _picker = ImagePicker();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController purposeController = TextEditingController();
  final TextEditingController vehicleController = TextEditingController();

  /* ============================
      PICK IMAGE FROM CAMERA
  ============================ */
  Future<void> pickImage() async {
    final XFile? picked =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);

    if (picked != null) {
      setState(() {
        visitorImage = File(picked.path);
      });
    }
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
    }

    setState(() => loading = false);
  }

  /* ============================
      CREATE VISITOR ENTRY WITH IMAGE
  ============================ */
  Future<void> submitVisitor() async {
    if (loading) return;

    if (nameController.text.trim().isEmpty ||
        mobileController.text.trim().length != 10 ||
        purposeController.text.trim().isEmpty ||
        selectedFlat == null ||
        visitorImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields & capture photo")),
      );
      return;
    }

    setState(() => loading = true);

    final response = await ApiService.multipart(
      "/visitors/create",
      {
        "personName": nameController.text.trim(),
        "personMobile": mobileController.text.trim(),
        "flatNo": selectedFlat,
        "purpose": purposeController.text.trim(),
        "vehicleNo": vehicleController.text.trim(),
        "entryType": "VISITOR",
      },
      file: visitorImage,
      fileFieldName: "photo", // must match backend field
    );

    setState(() => loading = false);

    if (response != null && response["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Visitor entry created successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response["message"] ?? "Upload failed")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchFlats();
  }

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    purposeController.dispose();
    vehicleController.dispose();
    super.dispose();
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
        FLAT SELECTION
  ============================ */
  Widget flatSelection() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: flats.length,
      itemBuilder: (context, index) {
        final flatNo = flats[index]["flatNo"];

        return InkWell(
          onTap: () {
            setState(() {
              selectedFlat = flatNo;
              flatSelected = true;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                flatNo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /* ============================
        VISITOR FORM
  ============================ */
  Widget visitorForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          GestureDetector(
            onTap: pickImage,
            child: CircleAvatar(
              radius: 55,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage:
                  visitorImage != null ? FileImage(visitorImage!) : null,
              child: visitorImage == null
                  ? const Icon(Icons.camera_alt,
                      size: 35, color: AppColors.primary)
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          const Text("Tap to capture photo"),
          const SizedBox(height: 24),
          _buildTextField(nameController, "Visitor Name", Icons.person),
          const SizedBox(height: 16),
          _buildTextField(mobileController, "Visitor Mobile", Icons.phone,
              isPhone: true),
          const SizedBox(height: 16),
          _buildTextField(purposeController, "Purpose", Icons.assignment),
          const SizedBox(height: 16),
          _buildTextField(
              vehicleController, "Vehicle Number", Icons.directions_car),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: submitVisitor,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("Create Visitor Entry"),
          )
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPhone = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.number : TextInputType.text,
      inputFormatters: isPhone ? [FilteringTextInputFormatter.digitsOnly] : [],
      maxLength: isPhone ? 10 : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        counterText: "",
      ),
    );
  }
}
