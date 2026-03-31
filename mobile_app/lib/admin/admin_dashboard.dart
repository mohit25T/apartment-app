import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/resident/resident_dashboard.dart';
import 'dart:convert';

import '../core/storage/role_storage.dart';
import '../core/storage/cache_service.dart';
import '../core/navigation/animation_navigation.dart';
import '../profile/profile_screen.dart';
import '../core/theme/app_theme.dart';
import '../core/api/api_service.dart';
import '../core/widgets/fade_in_slide.dart';
import '../core/widgets/walking_loader.dart';
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

  Future<void> checkSubscription() async {
    dynamic cachedRes;
    dynamic cachedPreview;

    // 1. Optimistic Cache Load
    try {
      cachedRes = await CacheService.getData("subscription_me");
      cachedPreview = await CacheService.getData("subscription_preview");
      if (cachedRes != null && mounted) {
        final status = cachedRes["status"]?.toString().toLowerCase();
        final endDateStr = cachedRes["endDate"];
        bool isActive = false;
        if (status == "active" && endDateStr != null) {
          final endDate = DateTime.parse(endDateStr);
          isActive = endDate.isAfter(DateTime.now());
        }
        setState(() {
          subscriptionActive = isActive;
          checkingSubscription = false;
          usedFlats = cachedPreview?["totalFlatsInDB"] ?? 0;
          allowedFlats = cachedPreview?["allowedFlats"] ?? 0;
          extraFlats = cachedPreview?["extraFlats"] ?? 0;
        });
      }
    } catch (_) {}

    // 2. Fetch fresh from API in background
    try {
      final responses = await Future.wait([
        ApiService.get("/subscription/current"),
        ApiService.get("/subscription/preview"),
      ]);
      final res = responses[0];
      final preview = responses[1];

      final String cachedResStr = jsonEncode(cachedRes ?? {});
      final String cachedPreviewStr = jsonEncode(cachedPreview ?? {});
      final String freshResStr = jsonEncode(res ?? {});
      final String freshPreviewStr = jsonEncode(preview ?? {});

      if (cachedResStr == freshResStr &&
          cachedPreviewStr == freshPreviewStr &&
          !checkingSubscription) {
        return; // No change, skip rebuild
      }

      // 🔥 ONLY UPDATE IF RESPONSE IS VALID AND NOT AN ERROR
      if (res != null && res["error"] != true) {
        await CacheService.saveData("subscription_me", res);
        
        if (preview != null && preview["error"] != true) {
           await CacheService.saveData("subscription_preview", preview);
        }

        final status = res["status"]?.toString().toLowerCase();
        final endDateStr = res["endDate"];

        bool isActive = false;
        if (status == "active" && endDateStr != null) {
          final endDate = DateTime.parse(endDateStr);
          isActive = endDate.isAfter(DateTime.now());
        }

        if (mounted) {
          setState(() {
            subscriptionActive = isActive;
            checkingSubscription = false;
            if (preview != null && preview["error"] != true) {
              usedFlats = preview["totalFlatsInDB"] ?? 0;
              allowedFlats = preview["allowedFlats"] ?? 0;
              extraFlats = preview["extraFlats"] ?? 0;
            }
          });
        }
      } else {
        // 🚨 API FAILED OR RETURNED ERROR -> KEEP CACHED STATE
        if (mounted) {
          setState(() => checkingSubscription = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => checkingSubscription = false);
      }
    }
  }

  bool get canSwitch =>
      roles.contains("ADMIN") &&
      (roles.contains("OWNER") || roles.contains("TENANT"));

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
              child:
                  const Icon(Icons.admin_panel_settings, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Admin Dashboard",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
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
          if (checkingSubscription)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white70),
                ),
              ),
            )
          else
            IconButton(
              tooltip: "Subscription",
              icon: Icon(
                Icons.workspace_premium_rounded,
                color: subscriptionActive ? Colors.amberAccent : Colors.white70,
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
                          ? NetworkImage(profileImage!)
                          : null,
                      child: profileImage == null
                          ? Icon(Icons.person,
                              color: Theme.of(context).primaryColor)
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
                if (checkingSubscription)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: WalkingLoader(size: 40)),
                  )
                else
                  FadeInSlide(delay: 0.05, child: _buildUpgradeCard()),

                if (canSwitch)
                  FadeInSlide(delay: 0.08, child: _buildSwitchModeCard()),

                const SizedBox(height: 12),

                Text(
                  "Quick Actions",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
                        child: _buildActionCard(
                            "Manage\nUsers",
                            Icons.groups_rounded,
                            Colors.orange,
                            "/society-users")),
                    FadeInSlide(
                        delay: 0.15,
                        child: _buildActionCard(
                            "Invite\nResident",
                            Icons.group_add_rounded,
                            Colors.blueAccent,
                            "/invite-resident")),
                    FadeInSlide(
                        delay: 0.2,
                        child: _buildActionCard(
                            "Pending\nTenants",
                            Icons.person_add_alt_1_rounded,
                            const Color(0xFFE57373),
                            "/pending-tenants")),
                    FadeInSlide(
                        delay: 0.25,
                        child: _buildActionCard(
                            "Invite\nGuard",
                            Icons.security_rounded,
                            Colors.green,
                            "/invite-guard")),
                    FadeInSlide(
                        delay: 0.3,
                        child: _buildActionCard(
                            "All\nMaintenance",
                            Icons.list_alt_rounded,
                            Colors.teal,
                            "/admin-maintenance-list")),
                    FadeInSlide(
                        delay: 0.35,
                        child: _buildActionCard(
                            "Generate\nMaintenance",
                            Icons.receipt_long_rounded,
                            Colors.deepPurple,
                            "/generate-maintenance")),
                    FadeInSlide(
                        delay: 0.4,
                        child: _buildActionCard(
                            "Manage\nComplaints",
                            Icons.admin_panel_settings_rounded,
                            Colors.redAccent,
                            "/admin-complaints")),
                    FadeInSlide(
                        delay: 0.45,
                        child: _buildActionCard(
                            "Create\nNotice",
                            Icons.post_add_rounded,
                            Colors.blue,
                            "/create-notice")),
                    FadeInSlide(
                        delay: 0.5,
                        child: _buildActionCard("View\nNotices",
                            Icons.campaign_rounded, Colors.indigo, "/notices")),
                    FadeInSlide(
                        delay: 0.55,
                        child: _buildActionCard(
                            "Manage\nVehicles",
                            Icons.directions_car,
                            Colors.deepPurpleAccent,
                            "/admin-vehicles")),
                    FadeInSlide(
                        delay: 0.6,
                        child: _buildActionCard(
                            "Manage\nContacts",
                            Icons.contact_phone_rounded,
                            Colors.green,
                            "/admin-contacts")),
                    FadeInSlide(
                        delay: 0.65,
                        child: _buildActionCard("SOS\nAlerts",
                            Icons.warning_rounded, Colors.red, "/admin-sos")),
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

  Widget _buildUpgradeCard() {
    final hasSubscription = subscriptionActive;
    final isLimitReached = hasSubscription && usedFlats > allowedFlats;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: !hasSubscription
            ? Colors.red.withOpacity(0.1)
            : isLimitReached
                ? Colors.red.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: !hasSubscription
              ? Colors.red.withOpacity(0.4)
              : isLimitReached
                  ? Colors.red.withOpacity(0.4)
                  : Colors.orange.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (!hasSubscription ? Colors.red : Colors.orange)
                .withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: !hasSubscription
                  ? Colors.red
                  : isLimitReached
                      ? Colors.red
                      : Colors.orange,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

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
                      fontSize: 14,
                    ),
                  )
                else ...[
                  Text(
                    "$usedFlats / $allowedFlats Flats Used",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.color
                          ?.withOpacity(0.9),
                      fontSize: 15,
                    ),
                  ),
                  if (extraFlats > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "$extraFlats extra flat(s) not covered ⚠",
                        style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ],
            ),
          ),

          ElevatedButton(
            onPressed: () {
              if (!subscriptionActive) {
                Navigator.pushNamed(context, "/subscription");
              } else if (usedFlats > allowedFlats) {
                Navigator.pushNamed(context, "/upgrade-subscription");
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MySubscriptionScreen()),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: !hasSubscription
                  ? Colors.red
                  : isLimitReached
                      ? Colors.red
                      : Colors.orange,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              !hasSubscription
                  ? "Subscribe"
                  : (usedFlats > allowedFlats)
                      ? "Upgrade"
                      : "View",
              style: const TextStyle(fontWeight: FontWeight.bold),
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
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0083B0).withOpacity(0.3),
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
          child: const Icon(Icons.home_rounded, color: Colors.white, size: 28),
        ),
        title: const Text(
          "Switch to Personal Mode",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: const Text(
          "Access your flat dashboard",
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            color: Colors.white, size: 20),
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
              width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
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