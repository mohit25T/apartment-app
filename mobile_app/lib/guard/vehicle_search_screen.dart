import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';

class GuardVehicleSearchScreen extends StatefulWidget {
  const GuardVehicleSearchScreen({super.key});

  @override
  State<GuardVehicleSearchScreen> createState() =>
      _GuardVehicleSearchScreenState();
}

class _GuardVehicleSearchScreenState
    extends State<GuardVehicleSearchScreen> {

  final TextEditingController controller = TextEditingController();
  Map? vehicle;

  Future<void> searchVehicle() async {

    final plate = controller.text.trim().toUpperCase();

    if (plate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter vehicle number")),
      );
      return;
    }

    final res =
        await ApiService.get("/vehicles/search?vehicleNumber=$plate");

    if (res != null && res["vehicle"] != null) {
      setState(() {
        vehicle = res["vehicle"];
      });
    } else {
      setState(() {
        vehicle = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vehicle not found")),
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("Vehicle Search"),
        backgroundColor: AppColors.primary,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// VEHICLE INPUT
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: "Vehicle Number",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            /// SEARCH BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: searchVehicle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text("Search"),
              ),
            ),

            const SizedBox(height: 20),

            /// RESULT
            if (vehicle != null)
              Card(
                elevation: 3,
                child: ListTile(
                  leading: const Icon(Icons.directions_car,
                      color: AppColors.primary),

                  title: Text(
                    vehicle!["vehicleNumber"] ?? "",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold),
                  ),

                  subtitle: Text(
                    "Flat: ${vehicle!["wing"]}-${vehicle!["flatNo"]}\n"
                    "Owner: ${vehicle!["residentId"]["name"]}",
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}
