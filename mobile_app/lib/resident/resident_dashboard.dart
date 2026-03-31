import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/admin/admin_dashboard.dart';
import 'package:mobile_app/core/navigation/animation_navigation.dart';
import '../core/storage/role_storage.dart';
import '../profile/profile_screen.dart';
import '../core/theme/app_theme.dart';
import '../core/api/api_service.dart';
import '../sos/resident_sos_screen.dart';
import '../core/widgets/fade_in_slide.dart';

class ResidentDashboard extends StatefulWidget {
  const ResidentDashboard({super.key});

  @override
  State<ResidentDashboard> createState() => _ResidentDashboardState();
}

class _ResidentDashboardState extends State<ResidentDashboard> {
  List<String> roles = [];
  String? profileImage;
  bool loadingProfile = true;

  static const String profileCacheKey = "RESIDENT_PROFILE_IMAGE";

  @override
  void initState() {
    super.initState();
    loadRoles();
    loadCachedProfile();
    fetchProfile();
  }

  Future<void> loadRoles() async {
    final data = await RoleStorage.getRoles();
    if (!mounted) return;

    setState(() {
      roles = data;
    });
  }

  Future<void> loadCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedImage = prefs.getString(profileCacheKey);

    if (cachedImage != null && mounted) {
      setState(() {
        profileImage = cachedImage;
        loadingProfile = false;
      });
    }
  }

  Future<void> fetchProfile() async {
    try {
      final response = await ApiService.get("/users/profile");

      if (response is Map && response["success"] == true) {
        final user = response["user"];

        final newImage = user?["profileImage"];
        final wing = user?["wing"];
        final flatNo = user?["flatNo"];

        final prefs = await SharedPreferences.getInstance();

        // Save profile image
        if (newImage != null) {
          await prefs.setString(profileCacheKey, newImage);
        }

        // Save wing
        if (wing != null) {
          await prefs.setString("RESIDENT_WING", wing);
        }

        // Save flat number
        if (flatNo != null) {
          await prefs.setString("RESIDENT_FLAT", flatNo);
        }

        if (mounted) {
          setState(() {
            profileImage = newImage;
          });
        }
      }
    } catch (e) {
      debugPrint("PROFILE FETCH ERROR: $e");
    }

    if (mounted) {
      setState(() => loadingProfile = false);
    }
  }
  
  bool get canSwitch =>
      roles.contains("ADMIN") &&
      (roles.contains("OWNER") || roles.contains("TENANT"));

  bool get isOwner => roles.contains("OWNER");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.home_filled, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Welcome Home",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Resident Dashboard",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ).then((_) => fetchProfile());
              },
              child: loadingProfile
                  ? const CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      ),
                    )
                  : CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).cardColor,
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
                if (canSwitch)
                  FadeInSlide(delay: 0.05, child: _buildSwitchModeCard()),
                if (canSwitch) const SizedBox(height: 16),
                
                if (isOwner) ...[
                  Text(
                    "Flat Management",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.headlineMedium?.color,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.15,
                    children: [
                      FadeInSlide(
                          delay: 0.1,
                          child: _buildFeatureCard(
                        "Invite\nTenant",
                        Icons.person_add_alt_1_rounded,
                        Colors.green,
                        "/invite-tenant",
                          )),
                      FadeInSlide(
                          delay: 0.15,
                          child: _buildFeatureCard(
                        "My\nTenant",
                        Icons.people_alt_rounded,
                        Colors.blue,
                        "/my-tenant",
                          )),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                
                Text(
                  "Notifications",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineMedium?.color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                FadeInSlide(
                    delay: 0.2,
                    child: _buildNotificationCard(
                  "Pending Visitor Approvals",
                  Icons.notifications_active_rounded,
                  Colors.orangeAccent,
                  "/resident-visitors",
                  "Action Required",
                    )),
                
                const SizedBox(height: 24),
                
                Text(
                  "My Features",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineMedium?.color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.15,
                  children: [

                    FadeInSlide(
                        delay: 0.25,
                        child: _buildFeatureCard(
                      "Pre-Approve\nGuest",
                      Icons.qr_code_rounded,
                      Colors.teal,
                      "/preapproved-guest",
                        )),

                    FadeInSlide(
                        delay: 0.3,
                        child: _buildFeatureCard(
                          "Visitor\nHistory",
                          Icons.history_rounded,
                          Colors.blueGrey,
                          "/resident-visitor-history",
                        )),
                    FadeInSlide(
                        delay: 0.35,
                        child: _buildFeatureCard(
                          "Maintenance\nBills",
                          Icons.receipt_long_rounded,
                          Colors.deepPurple,
                          "/maintenance",
                        )),
                    FadeInSlide(
                        delay: 0.4,
                        child: _buildFeatureCard(
                      "Raise\nComplaint",
                      Icons.report_problem_rounded,
                      Colors.redAccent,
                      "/complaint-create",
                        )),

                    FadeInSlide(
                        delay: 0.45,
                        child: _buildFeatureCard(
                      "My\nComplaints",
                      Icons.list_alt_rounded,
                      Colors.deepOrange,
                      "/my-complaints",
                        )),

                    FadeInSlide(
                        delay: 0.5,
                        child: _buildFeatureCard(
                          "My\nVehicles",
                          Icons.directions_car_rounded,
                          Colors.green,
                          "/resident-vehicles",
                        )),
                    FadeInSlide(
                        delay: 0.55,
                        child: _buildFeatureCard(
                      "Notices",
                      Icons.campaign_rounded,
                      Colors.indigo,
                      "/notices",
                        )),
                    FadeInSlide(
                        delay: 0.6,
                        child: _buildFeatureCard(
                      "Contacts",
                      Icons.contact_phone_rounded,
                      Colors.green,
                      "/contacts",
                        )),

                    FadeInSlide(
                        delay: 0.65,
                        child: _buildFeatureCard(
                      "My\nProfile",
                      Icons.person_rounded,
                      Colors.indigo,
                      "/profile",
                        )),

                    FadeInSlide(
                        delay: 0.7,
                        child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ResidentSOSScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.red.withOpacity(0.2),
                                  width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.08),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.sos_rounded,
                                      color: Colors.red, size: 32),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                              "Emergency\nSOS",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                        )),

                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 30,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFF1E88E5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
    );
  }

  Widget _buildSwitchModeCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5A4FCF), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A4FCF).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.admin_panel_settings_rounded,
              color: Colors.white, size: 28),
        ),
        title: const Text(
          "Switch to Admin",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: const Text(
          "Access admin controls",
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            color: Colors.white, size: 20),
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(badgeText,
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 18, color: Colors.grey.shade400),
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
              width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.color
                    ?.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
