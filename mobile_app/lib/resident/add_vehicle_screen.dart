import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {

  final TextEditingController numberController = TextEditingController();
  final TextEditingController parkingController = TextEditingController();

  String vehicleType = "CAR";

  final RegExp plateRegex =
      RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{2}[0-9]{4}$');

  /* ===============================
     ADD VEHICLE
  =============================== */

  Future<void> addVehicle() async {

    String plate = numberController.text.trim().toUpperCase();

    if (plate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter vehicle number")),
      );
      return;
    }

    if (!plateRegex.hasMatch(plate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid number plate format")),
      );
      return;
    }

    final response = await ApiService.post("/vehicles/create", {
      "vehicleNumber": plate,
      "vehicleType": vehicleType,
      "parkingSlot": parkingController.text.trim()
    });

    if (response != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vehicle added successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to add vehicle"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    numberController.dispose();
    parkingController.dispose();
    super.dispose();
  }

  /* ===============================
     UI
  =============================== */

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("Add Vehicle"),
        backgroundColor: AppColors.primary,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// VEHICLE NUMBER
            TextField(
              controller: numberController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: "Vehicle Number",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            /// VEHICLE TYPE
            DropdownButtonFormField<String>(
              value: vehicleType,
              items: const [
                DropdownMenuItem(value: "CAR", child: Text("Car")),
                DropdownMenuItem(value: "BIKE", child: Text("Bike")),
                DropdownMenuItem(value: "SCOOTER", child: Text("Scooter")),
              ],
              onChanged: (value) {
                setState(() => vehicleType = value!);
              },
              decoration: const InputDecoration(
                labelText: "Vehicle Type",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            /// PARKING SLOT
            TextField(
              controller: parkingController,
              decoration: const InputDecoration(
                labelText: "Parking Slot",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            /// SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: addVehicle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text("Save Vehicle"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
