import 'package:flutter/material.dart';
import 'package:mobile_app/resident/resident_dashboard.dart';
import '../core/storage/role_storage.dart';
import '../core/navigation/animation_navigation.dart';
import '../profile/profile_screen.dart'; // ✅ added

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
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

  bool get canSwitch => roles.contains("ADMIN") && roles.contains("RESIDENT");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Admin Dashboard"),
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
                  const ResidentDashboard(),
                  fromRight: true,
                );
              },
              child: const Text(
                "Resident Mode",
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
              "Invite Resident",
              Icons.group_add,
              route: "/invite-resident",
            ),
             _card(
              "Residents & Guards",
              Icons.groups_outlined,
              route: "/society-users",
            ),
            _card("Invite Guard", Icons.security, route: "/invite-guard"),
            _card("Society Visitor Logs", Icons.list_alt,
                route: "/society-visitors"),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, IconData icon, {String? route}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        leading: Icon(icon, size: 28),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: route == null ? null : () => Navigator.pushNamed(context, route),
      ),
    );
  }
}
