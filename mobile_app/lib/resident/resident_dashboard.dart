import 'package:flutter/material.dart';
import 'package:mobile_app/admin/admin_dashboard.dart';
import 'package:mobile_app/core/navigation/animation_navigation.dart';
import '../core/storage/role_storage.dart';
import '../profile/profile_screen.dart'; // ✅ added

class ResidentDashboard extends StatefulWidget {
  const ResidentDashboard({super.key});

  @override
  State<ResidentDashboard> createState() => _ResidentDashboardState();
}

class _ResidentDashboardState extends State<ResidentDashboard> {
  List<String> roles = [];

  @override
  void initState() {
    super.initState();
    loadRoles();
  }

  Future<void> loadRoles() async {
    final data = await RoleStorage.getRoles();
    setState(() {
      roles = data;
    });
  }

  bool get canSwitch =>
      roles.contains("ADMIN") && roles.contains("RESIDENT");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Resident Dashboard"),
        centerTitle: true,
        actions: [
          // ✅ PROFILE BUTTON (added)
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
          ),

          // existing code (unchanged)
          if (canSwitch)
            TextButton(
              onPressed: () {
                AnimatedNavigation.pushReplacement(
                  context,
                  const AdminDashboard(),
                  fromRight: false,
                );
              },
              child: const Text(
                "Admin Mode",
                style: TextStyle(color: Colors.black),
              ),
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _card(
              title: "Pending Visitor Approvals",
              icon: Icons.notifications_active,
              route: "/resident-visitors",
            ),

            _card(
              title: "Pre-Approved Guest (OTP)",
              icon: Icons.verified_user,
              route: "/preapproved-guest",
            ),

            _card(
              title: "Visitor History",
              icon: Icons.history,
              route: "/resident-visitor-history",
            ),

            // 🔹 EXISTING PROFILE CARD — UNTOUCHED
            _card(
              title: "Profile",
              icon: Icons.person,
              route: "/profile",
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required String title,
    required IconData icon,
    required String route,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        leading: Icon(icon, size: 28),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.pushNamed(context, route);
        },
      ),
    );
  }
}
