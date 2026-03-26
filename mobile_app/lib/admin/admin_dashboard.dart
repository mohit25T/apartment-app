import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/resident/resident_dashboard.dart';

import '../core/storage/role_storage.dart';
import '../core/navigation/animation_navigation.dart';
import '../profile/profile_screen.dart';
import '../core/theme/app_theme.dart';
import '../core/api/api_service.dart';
import 'my_subscription_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<String> roles = [];

  String? profileImage;
  String? wing;

  bool loadingProfile = true;

  // 🔥 Subscription states
  bool subscriptionActive = false;
  bool checkingSubscription = true;

  int usedFlats = 0;
  int allowedFlats = 0;
  int extraFlats = 0;

  static const String profileCacheKey = "ADMIN_PROFILE_IMAGE";

  @override
  void initState() {
    super.initState();
    loadRoles();
    loadCachedProfile();
    fetchProfile();
    checkSubscription();
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

  // ===============================
  // FETCH PROFILE
  // ===============================
  Future<void> fetchProfile() async {
    try {
      final response = await ApiService.get("/users/profile");

      if (response != null && response["user"] != null) {
        final user = response["user"];

        final newImage = user["profileImage"];
        final newWing = user["wing"];

        if (mounted) {
          setState(() {
            wing = newWing;
          });
        }

        if (newImage != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(profileCacheKey, newImage);

          if (mounted) {
            setState(() {
              profileImage = newImage;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("PROFILE FETCH ERROR: $e");
    }

    if (mounted) {
      setState(() => loadingProfile = false);
    }
  }

  // ===============================
  // 🔥 CHECK SUBSCRIPTION (FIXED)
  // ===============================
  Future<void> checkSubscription() async {
    try {
      final res = await ApiService.get("/subscription/me");
      final preview = await ApiService.get("/subscription/preview");

      bool isActive = false;

      if (res != null) {
        final status = res["status"]?.toString().toLowerCase();
        final endDateStr = res["endDate"];

        if (status == "active" && endDateStr != null) {
          final endDate = DateTime.parse(endDateStr);
          isActive = endDate.isAfter(DateTime.now());
        }
      }

      if (mounted) {
        setState(() {
          subscriptionActive = isActive;
          checkingSubscription = false;
          usedFlats = preview?["totalFlatsInDB"] ?? 0;
          allowedFlats = preview?["allowedFlats"] ?? 0;
          extraFlats = preview?["extraFlats"] ?? 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          subscriptionActive = false;
          checkingSubscription = false;
        });
      }
    }
  }

  bool get canSwitch =>
      roles.contains("ADMIN") &&
      (roles.contains("OWNER") || roles.contains("TENANT"));

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
              child: Icon(Icons.admin_panel_settings, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Admin Dashboard",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  wing != null
                      ? "Wing $wing • Manage Society"
                      : "Manage Society",
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
          if (!checkingSubscription)
            IconButton(
              tooltip: "Subscription",
              icon: Icon(
                Icons.workspace_premium_rounded,
                color: subscriptionActive ? Colors.amberAccent : Colors.white,
              ),
              onPressed: () {
                if (subscriptionActive) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MySubscriptionScreen()),
                  ).then((_) => checkSubscription());
                } else {
                  Navigator.pushNamed(context, "/subscription")
                      .then((_) => checkSubscription());
                }
              },
            ),

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
                          ? NetworkImage(profileImage!)
                          : null,
                      child: profileImage == null
                          ? const Icon(Icons.person,
                              color: AppColors.primary)
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

                // ✅ ONLY ONE BANNER
                if (!checkingSubscription) _buildUpgradeCard(),

                if (canSwitch) _buildSwitchModeCard(),

                const SizedBox(height: 20),

                const Text(
                  "Quick Actions",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 16),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildActionCard("SOS\nAlerts", Icons.warning_rounded,
                        Colors.red, "/admin-sos"),
                    _buildActionCard(
                        "Generate\nMaintenance",
                        Icons.receipt_long_rounded,
                        Colors.deepPurple,
                        "/generate-maintenance"),
                    _buildActionCard("All\nMaintenance", Icons.list_alt_rounded,
                        Colors.teal, "/admin-maintenance-list"),
                    _buildActionCard(
                        "Invite\nResident",
                        Icons.group_add_rounded,
                        Colors.blueAccent,
                        "/invite-resident"),
                    _buildActionCard(
                        "Pending\nTenants",
                        Icons.person_add_alt_1_rounded,
                        Colors.redAccent,
                        "/pending-tenants"),
                    _buildActionCard("Manage\nUsers", Icons.groups_rounded,
                        Colors.orangeAccent, "/society-users"),
                    _buildActionCard("Invite\nGuard", Icons.security_rounded,
                        Colors.green, "/invite-guard"),
                    _buildActionCard(
                        "Manage\nComplaints",
                        Icons.admin_panel_settings_rounded,
                        Colors.red,
                        "/admin-complaints"),
                    _buildActionCard("Create\nNotice", Icons.post_add_rounded,
                        Colors.blue, "/create-notice"),
                    _buildActionCard("View\nNotices", Icons.campaign_rounded,
                        Colors.indigo, "/notices"),
                    _buildActionCard("Manage\nVehicles", Icons.directions_car,
                        Colors.deepPurple, "/admin-vehicles"),
                    _buildActionCard(
                        "Manage\nContacts",
                        Icons.contact_phone_rounded,
                        Colors.green,
                        "/admin-contacts"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // 🔥 SINGLE SMART BANNER
  // ===============================
  Widget _buildUpgradeCard() {
    final hasSubscription = subscriptionActive;
    final isLimitReached = hasSubscription && usedFlats > allowedFlats;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: !hasSubscription
            ? Colors.red.shade50
            : isLimitReached
                ? Colors.red.shade50
                : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: !hasSubscription
              ? Colors.red
              : isLimitReached
                  ? Colors.red
                  : Colors.orange,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.workspace_premium,
            color: !hasSubscription
                ? Colors.red
                : isLimitReached
                    ? Colors.red
                    : Colors.orange,
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!hasSubscription)
                  const Text(
                    "No active subscription. Please subscribe.",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  )
                else ...[
                  // ✅ FIXED (NO preview)
                  Text(
                    "$usedFlats / $allowedFlats Flats Used",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  if (extraFlats > 0)
                    Text(
                      "$extraFlats extra flat(s) not covered ⚠",
                      style: const TextStyle(color: Colors.red),
                    ),
                ],
              ],
            ),
          ),

          TextButton(
            onPressed: () {
              if (!subscriptionActive) {
                Navigator.pushNamed(context, "/subscription");
              } else if (usedFlats > allowedFlats) {
                Navigator.pushNamed(context, "/upgrade-subscription");
              }
              else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MySubscriptionScreen()),
                );
              }
            },
            child: Text(!hasSubscription
                ? "Subscribe"
                : (usedFlats > allowedFlats)
                    ? "Upgrade"
                    : "View"),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade400, Colors.teal.shade700],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: const Icon(Icons.home_rounded, color: Colors.white),
        title: const Text(
          "Switch to Personal Mode",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          "Access your flat dashboard",
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            color: Colors.white, size: 16),
        onTap: () {
          AnimatedNavigation.pushReplacement(
            context,
            const ResidentDashboard(),
            fromRight: true,
          );
        },
      ),
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, String route) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}