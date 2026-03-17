import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../core/api/api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/walking_loader.dart';
import 'add_vehicle_screen.dart';
import 'edit_vehicle_screen.dart';

class ResidentVehicleListScreen extends StatefulWidget {
  const ResidentVehicleListScreen({super.key});

  @override
  State<ResidentVehicleListScreen> createState() =>
      _ResidentVehicleListScreenState();
}

class _ResidentVehicleListScreenState extends State<ResidentVehicleListScreen> {
  List vehicles = [];
  bool loading = true;

  static const cacheKey = "resident_vehicle_cache";

  @override
  void initState() {
    super.initState();
    loadCachedVehicles();
    loadVehicles();
  }

  Future<void> loadCachedVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(cacheKey);

    if (cached != null) {
      setState(() {
        vehicles = jsonDecode(cached);
        loading = false;
      });
    }
  }

  Future<void> saveCache(List data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cacheKey, jsonEncode(data));
  }

  Future<void> loadVehicles() async {
    final res = await ApiService.get("/vehicles/my");

    if (res != null && res["vehicles"] != null) {
      setState(() {
        vehicles = res["vehicles"];
        loading = false;
      });

      saveCache(vehicles);
    }
  }

  Future<void> deleteVehicle(String id) async {
    await ApiService.delete("/vehicles/delete/$id");
    loadVehicles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("My Vehicles"),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadVehicles,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddVehicleScreen(),
            ),
          );
          loadVehicles();
        },
      ),
      body: loading
          ? const Center(child: WalkingLoader(size: 60))
          : vehicles.isEmpty
              ? const Center(child: Text("No vehicles found"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vehicles.length,
                  itemBuilder: (context, index) {
                    final v = vehicles[index];

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: const Icon(Icons.directions_car),
                        title: Text(
                          v["vehicleNumber"],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                            "Parking: ${v["parkingSlot"] ?? "Not assigned"}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EditVehicleScreen(vehicle: v),
                                  ),
                                );
                                loadVehicles();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteVehicle(v["_id"]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
