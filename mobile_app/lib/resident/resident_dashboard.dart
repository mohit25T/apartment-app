import 'package:flutter/material.dart';
import 'package:mobile_app/admin/admin_dashboard.dart';
import 'package:mobile_app/core/navigation/animation_navigation.dart';
import '../core/storage/role_storage.dart';
import '../profile/profile_screen.dart';
import '../core/theme/app_theme.dart';
import '../core/api/api_service.dart';

class ResidentDashboard extends StatefulWidget {
  const ResidentDashboard({super.key});

  @override
  State<ResidentDashboard> createState() => _ResidentDashboardState();
}

class _ResidentDashboardState extends State<ResidentDashboard> {
  List<String> roles = [];
  String? profileImage;
  bool loadingProfile = true;

  @override
  void initState() {
    super.initState();
    loadRoles();
    fetchProfile();
  }

  Future<void> loadRoles() async {
    final data = await RoleStorage.getRoles();
    setState(() {
      roles = data;
    });
  }

  Future<void> fetchProfile() async {
    setState(() => loadingProfile = true);

    final response = await ApiService.get("/users/profile");

    if (response != null && response["success"] == true) {
      profileImage = response["user"]["profileImage"];
    }

    setState(() => loadingProfile = false);
  }

  bool get canSwitch =>
      roles.contains("ADMIN") &&
      (roles.contains("OWNER") || roles.contains("TENANT"));

  bool get isOwner => roles.contains("OWNER");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.home_filled, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Welcome Home",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Resident Dashboard",
                  style: TextStyle(
                      fontSize: 12, color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ).then((_) => fetchProfile());
              },
              child: loadingProfile
                  ? const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      backgroundImage: profileImage != null
                          ? NetworkImage(
                              profileImage! +
                                  "?t=${DateTime.now().millisecondsSinceEpoch}",
                            )
                          : null,
                      child: profileImage == null
                          ? const Icon(Icons.person, color: AppColors.primary)
                          : null,
                    ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (canSwitch) _buildSwitchModeCard(),
                const SizedBox(height: 20),

                // ✅ FLAT MANAGEMENT SECTION (OWNER ONLY)
                if (isOwner) ...[
                  const Text(
                    "Flat Management",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      _buildFeatureCard(
                        "Invite\nTenant",
                        Icons.person_add_alt_1_rounded,
                        Colors.green,
                        "/invite-tenant",
                      ),
                      _buildFeatureCard(
                        "My\nTenant",
                        Icons.people_alt_rounded,
                        Colors.blue,
                        "/my-tenant",
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                const Text(
                  "Notifications",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildNotificationCard(
                  "Pending Visitor Approvals",
                  Icons.notifications_active_rounded,
                  Colors.orangeAccent,
                  "/resident-visitors",
                  "Action Required",
                ),
                const SizedBox(height: 24),

                const Text(
                  "My Features",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildFeatureCard(
                      "Maintenance\nBills",
                      Icons.receipt_long_rounded,
                      Colors.deepPurple,
                      "/maintenance",
                    ),
                    _buildFeatureCard(
                      "Pre-Approve\nGuest",
                      Icons.qr_code_rounded,
                      Colors.teal,
                      "/preapproved-guest",
                    ),
                    _buildFeatureCard(
                      "Raise\nComplaint",
                      Icons.report_problem_rounded,
                      Colors.redAccent,
                      "/complaint-create",
                    ),
                    _buildFeatureCard(
                      "My\nComplaints",
                      Icons.list_alt_rounded,
                      Colors.deepOrange,
                      "/my-complaints",
                    ),
                    _buildFeatureCard(
                      "Notices",
                      Icons.campaign_rounded,
                      Colors.indigo,
                      "/notices",
                    ),
                    _buildFeatureCard(
                      "Visitor\nHistory",
                      Icons.history_rounded,
                      Colors.blueGrey,
                      "/resident-visitor-history",
                    ),
                    _buildFeatureCard(
                      "My\nProfile",
                      Icons.person_rounded,
                      Colors.indigo,
                      "/profile",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 20,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
    );
  }

  Widget _buildSwitchModeCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: const Icon(Icons.admin_panel_settings_rounded,
            color: AppColors.primary),
        title: const Text("Switch to Admin",
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text("Access admin controls"),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () {
          AnimatedNavigation.pushReplacement(
            context,
            const AdminDashboard(),
            fromRight: false,
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(String title, IconData icon, Color color,
      String route, String badgeText) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
      String title, IconData icon, Color color, String route) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
