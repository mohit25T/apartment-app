import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';

class AdminVehicleListScreen extends StatefulWidget {
  const AdminVehicleListScreen({super.key});

  @override
  State<AdminVehicleListScreen> createState() =>
      _AdminVehicleListScreenState();
}

class _AdminVehicleListScreenState extends State<AdminVehicleListScreen> {

  List vehicles = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadVehicles();
  }

  Future<void> loadVehicles() async {

    final res = await ApiService.get("/vehicles/all");

    if (res != null) {
      setState(() {
        vehicles = res["vehicles"];
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("All Vehicles"),
        backgroundColor: AppColors.primary,
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vehicles.length,
              itemBuilder: (context, index) {

                final v = vehicles[index];

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.directions_car),
                    title: Text(v["vehicleNumber"]),
                    subtitle: Text(
                        "Flat: ${v["residentId"]?["wing"]??""} - ${v["residentId"]["flatNo"]}\nOwner: ${v["residentId"]["name"]}"),
                  ),
                );
              },
            ),
    );
  }
}