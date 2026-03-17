import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_service.dart';

class ResidentSOSScreen extends StatefulWidget {
  const ResidentSOSScreen({super.key});

  @override
  State<ResidentSOSScreen> createState() => _ResidentSOSScreenState();
}

class _ResidentSOSScreenState extends State<ResidentSOSScreen>
    with SingleTickerProviderStateMixin {

  String emergencyType = "security";

  String? wing;
  String? flatNo;

  bool loading = false;

  late AnimationController holdController;

  @override
  void initState() {
    super.initState();

    loadResidentDetails();

    holdController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        holdController.reset();
        triggerSOS();
      }
    });
  }

  Future<void> loadResidentDetails() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      wing = prefs.getString("RESIDENT_WING");
      flatNo = prefs.getString("RESIDENT_FLAT");
    });

    debugPrint("Wing loaded => $wing");
    debugPrint("Flat loaded => $flatNo");
  }

  @override
  void dispose() {
    holdController.dispose();
    super.dispose();
  }

  Future<void> triggerSOS() async {

    if (wing == null || flatNo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Flat details not available")),
      );
      return;
    }

    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Trigger SOS"),
        content: const Text(
            "Are you sure you want to send an emergency alert to security?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text("Confirm"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      loading = true;
    });

    try {

      final payload = {
        "wing": wing,
        "flatNo": flatNo,
        "emergencyType": emergencyType
      };

      debugPrint("Sending SOS payload => $payload");

      final response = await ApiService.post(
        "/sos/trigger",
        payload,
      );

      if (response["success"] == true) {

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🚨 SOS Alert Sent Successfully"),
          ),
        );

      } else {

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response["message"] ?? "Failed to send SOS"),
          ),
        );

      }

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );

    }

    setState(() {
      loading = false;
    });
  }

  void startHolding() {
    if (!loading) {
      holdController.forward();
    }
  }

  void stopHolding() {
    if (holdController.isAnimating) {
      holdController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency SOS"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const SizedBox(height: 20),

            const Text(
              "Select Emergency Type",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: emergencyType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: "medical",
                  child: Text("Medical"),
                ),
                DropdownMenuItem(
                  value: "fire",
                  child: Text("Fire"),
                ),
                DropdownMenuItem(
                  value: "security",
                  child: Text("Security"),
                ),
              ],
              onChanged: (val) {
                setState(() {
                  emergencyType = val!;
                });
              },
            ),

            const Spacer(),

            GestureDetector(
              onLongPressStart: (_) => startHolding(),
              onLongPressEnd: (_) => stopHolding(),
              child: Stack(
                alignment: Alignment.center,
                children: [

                  SizedBox(
                    height: 220,
                    width: 220,
                    child: AnimatedBuilder(
                      animation: holdController,
                      builder: (context, child) {
                        return CircularProgressIndicator(
                          value: holdController.value,
                          strokeWidth: 8,
                          backgroundColor: Colors.red.shade100,
                          valueColor:
                          const AlwaysStoppedAnimation(Colors.red),
                        );
                      },
                    ),
                  ),

                  Container(
                    height: 180,
                    width: 180,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent,
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: Center(
                      child: loading
                          ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                          : const Text(
                        "HOLD\nSOS",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            const Text(
              "Press and hold the SOS button for 3 seconds in case of emergency.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

          ],
        ),
      ),
    );
  }
}