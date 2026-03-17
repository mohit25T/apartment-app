import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';

class EditVehicleScreen extends StatefulWidget {
  final Map vehicle;

  const EditVehicleScreen({super.key, required this.vehicle});

  @override
  State<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {

  late TextEditingController numberController;
  late TextEditingController parkingController;

  String vehicleType = "CAR";

  final RegExp plateRegex =
      RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{2}[0-9]{4}$');

  @override
  void initState() {
    super.initState();

    numberController =
        TextEditingController(text: widget.vehicle["vehicleNumber"]);

    parkingController =
        TextEditingController(text: widget.vehicle["parkingSlot"]);

    vehicleType = widget.vehicle["vehicleType"] ?? "CAR";
  }

  /* ===============================
     UPDATE VEHICLE
  =============================== */

  Future<void> updateVehicle() async {

    String plate = numberController.text.trim().toUpperCase();

    if (!plateRegex.hasMatch(plate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid vehicle number")),
      );
      return;
    }

    final response = await ApiService.put(
      "/vehicles/update/${widget.vehicle["_id"]}",
      {
        "vehicleNumber": plate,
        "vehicleType": vehicleType,
        "parkingSlot": parkingController.text.trim()
      },
    );

    if (response != null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vehicle updated successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update vehicle"),
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
        title: const Text("Edit Vehicle"),
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

            /// UPDATE BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: updateVehicle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text("Update Vehicle"),
              ),
            )

          ],
        ),
      ),
    );
  }
}
