import 'package:flutter/material.dart';
import '../profile/profile_screen.dart'; // ✅ added

class GuardDashboard extends StatelessWidget {
  const GuardDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Security Dashboard"),
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
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _card(
              context,
              title: "New Visitor Entry",
              icon: Icons.person_add,
              route: "/visitor-entry",
            ),

            _card(
              context,
              title: "Delivery Entry",
              icon: Icons.local_shipping,
              route: "/delivery-entry",
            ),

            _card(
              context,
              title: "Pre-Approved Guest",
              icon: Icons.verified_user,
              route: "/guest-otp",
            ),

            _card(
              context,
              title: "Today's Visitors",
              icon: Icons.history,
              route: "/visitors",
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String route,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, size: 30),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.pushNamed(context, route);
        },
      ),
    );
  }
}
