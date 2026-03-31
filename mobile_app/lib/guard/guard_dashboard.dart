import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../profile/profile_screen.dart';
import '../core/theme/app_theme.dart';
import '../core/api/api_service.dart';
import '../sos/guard_sos_screen.dart';
import '../core/widgets/fade_in_slide.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.security, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Security Operations",
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
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
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
                          ? Icon(
                              Icons.person,
                              color: Theme.of(context).primaryColor,
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

                FadeInSlide(delay: 0.1, child: _buildActionCard(
                  context,
                  title: "Guest with Pass",
                  subtitle: "Verify OTP or Code",
                  icon: Icons.verified_user_rounded,
                  color: Colors.green,
                  route: "/guest-otp",
                )),

                FadeInSlide(delay: 0.15, child: _buildActionCard(
                  context,
                  title: "Visitor Entry",
                  subtitle: "Log new visitor arrival",
                  icon: Icons.person_add_rounded,
                  color: Colors.blueAccent,
                  route: "/visitor-entry",
                )),

                FadeInSlide(delay: 0.2, child: _buildActionCard(
                  context,
                  title: "Delivery Entry",
                  subtitle: "Log package delivery",
                  icon: Icons.local_shipping_rounded,
                  color: Colors.orangeAccent,
                  route: "/delivery-entry",
                )),

                FadeInSlide(delay: 0.25, child: _buildActionCard(
                  context,
                  title: "Visitor Log",
                  subtitle: "View today's visitors",
                  icon: Icons.history_rounded,
                  color: Colors.purpleAccent,
                  route: "/visitors",
                )),

                FadeInSlide(delay: 0.3, child: _buildActionCard(
                  context,
                  title: "Vehicle Search",
                  subtitle: "Find vehicle owner by number plate",
                  icon: Icons.directions_car_rounded,
                  color: Colors.indigo,
                  route: "/vehicle-search",
                )),
                
                FadeInSlide(delay: 0.35, child: _buildActionCard(
                  context,
                  title: "Contacts",
                  subtitle: "Call emergency & society contacts",
                  icon: Icons.contact_phone_rounded,
                  color: Colors.green,
                  route: "/contacts",
                )),

                FadeInSlide(delay: 0.4, child: _buildActionCard(
                  context,
                  title: "SOS Alerts",
                  subtitle: "View emergency alerts from residents",
                  icon: Icons.warning_rounded,
                  color: Colors.red,
                  route: "SOS_SCREEN",
                )),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftStatus() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOnDuty ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isOnDuty ? Colors.green : Colors.red).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isOnDuty ? Icons.check_circle : Icons.block,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              isOnDuty
                  ? "ON DUTY • Shift $shiftStart - $shiftEnd"
                  : "OFF DUTY • Shift $shiftStart - $shiftEnd",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 5),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}
