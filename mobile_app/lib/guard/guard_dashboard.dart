import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../profile/profile_screen.dart';
import '../core/theme/app_theme.dart';
import '../core/api/api_service.dart';
import '../sos/guard_sos_screen.dart';

class GuardDashboard extends StatefulWidget {
  const GuardDashboard({super.key});

  @override
  State<GuardDashboard> createState() => _GuardDashboardState();
}

class _GuardDashboardState extends State<GuardDashboard> {
  String? profileImage;
  bool loadingProfile = true;

  bool isOnDuty = false;
  String shiftStart = "";
  String shiftEnd = "";

  static const String profileCacheKey = "GUARD_PROFILE_IMAGE";

  @override
  void initState() {
    super.initState();
    loadCachedProfile();
    fetchProfile();
    loadShiftInfo();
  }

  Future<void> loadShiftInfo() async {
    final prefs = await SharedPreferences.getInstance();

    shiftStart = prefs.getString("shiftStartTime") ?? "";
    shiftEnd = prefs.getString("shiftEndTime") ?? "";

    if (shiftStart.isNotEmpty && shiftEnd.isNotEmpty) {
      isOnDuty = checkShift(shiftStart, shiftEnd);
    }

    if (mounted) {
      setState(() {});
    }
  }

  bool checkShift(String start, String end) {
    final now = DateTime.now();

    final startParts = start.split(":");
    final endParts = end.split(":");

    final startMinutes =
        int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    final currentMinutes = now.hour * 60 + now.minute;

    if (startMinutes < endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
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

      if (response != null && response["success"] == true) {
        final newImage = response["user"]["profileImage"];

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
              child: Icon(Icons.security, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Security Operations",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Guard Dashboard",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const Text(
                  "Society Security",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
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
                          ? const Icon(
                              Icons.person,
                              color: AppColors.primary,
                            )
                          : null,
                    ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildShiftStatus(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [

                _buildActionCard(
                  context,
                  title: "SOS Alerts",
                  subtitle: "View emergency alerts from residents",
                  icon: Icons.warning_rounded,
                  color: Colors.red,
                  route: "SOS_SCREEN",
                ),

                _buildActionCard(
                  context,
                  title: "Visitor Entry",
                  subtitle: "Log new visitor arrival",
                  icon: Icons.person_add_rounded,
                  color: Colors.blueAccent,
                  route: "/visitor-entry",
                ),

                _buildActionCard(
                  context,
                  title: "Delivery Entry",
                  subtitle: "Log package delivery",
                  icon: Icons.local_shipping_rounded,
                  color: Colors.orangeAccent,
                  route: "/delivery-entry",
                ),

                _buildActionCard(
                  context,
                  title: "Guest with Pass",
                  subtitle: "Verify OTP or Code",
                  icon: Icons.verified_user_rounded,
                  color: Colors.green,
                  route: "/guest-otp",
                ),

                _buildActionCard(
                  context,
                  title: "Visitor Log",
                  subtitle: "View today's visitors",
                  icon: Icons.history_rounded,
                  color: Colors.purpleAccent,
                  route: "/visitors",
                ),
                
                _buildActionCard(
                  context,
                  title: "Contacts",
                  subtitle: "Call emergency & society contacts",
                  icon: Icons.contact_phone_rounded,
                  color: Colors.green,
                  route: "/contacts",
                ),

                _buildActionCard(
                  context,
                  title: "Vehicle Search",
                  subtitle: "Find vehicle owner by number plate",
                  icon: Icons.directions_car_rounded,
                  color: Colors.indigo,
                  route: "/vehicle-search",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftStatus() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOnDuty ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isOnDuty ? Icons.check_circle : Icons.block,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isOnDuty
                  ? "ON DUTY • Shift $shiftStart - $shiftEnd"
                  : "OFF DUTY • Shift $shiftStart - $shiftEnd",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
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

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return InkWell(
      onTap: () {
        if (!isOnDuty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Your shift is not active right now"),
            ),
          );
          return;
        }

        if (route == "SOS_SCREEN") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const GuardSOSAlertScreen(),
            ),
          );
        } else {
          Navigator.pushNamed(context, route);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border(left: BorderSide(color: color, width: 6)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
