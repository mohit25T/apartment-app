import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';
import '../core/storage/user_storage.dart';
import '../core/api/api_service.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  double _logoOpacity = 0.0;
  double _appOpacity = 0.0;
  double _userOpacity = 0.0;
  String? _userName;
  bool _showUser = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    // 1. Fade In Logo
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _logoOpacity = 1.0);

    // 2. Fade In App Name
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _appOpacity = 1.0);

    // 3. Check Auth & Get User Name
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) await _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final String? role = prefs.getString('role');

    if (isLoggedIn && role != null) {
      // 4. Get User Name
      String? name = await UserStorage.getName();
      
      // ⚠️ IF NAME MISSING (Existing sessions), FETCH FROM API
      if (name == null || name.isEmpty) {
        try {
          final response = await ApiService.get("/users/profile");
          if (response != null && response["success"] == true && response["user"] != null) {
            final user = response["user"];
            name = user["name"];
            await UserStorage.saveUser(
              name: name,
              email: user["email"],
              mobile: user["mobile"],
            );
          }
        } catch (e) {
          debugPrint("Authorized check profile fetch failed: $e");
        }
      }
      
      if (name != null && name.isNotEmpty) {
        if (mounted) {
          setState(() {
            _userName = name;
            _showUser = true;
          });
        }
        
        // 5. Fade In User Name
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) setState(() => _userOpacity = 1.0);
        
        // 6. Wait and Navigate
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) _navigate(role);
      } else {
        // No name found, just navigate
        if (mounted) _navigate(role);
      }
    } else {
      // Not logged in -> Login Screen
      // Wait a bit to let the logo be seen
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _navigate(String role) {
    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin');
    } else if (role == 'resident') {
      Navigator.pushReplacementNamed(context, '/resident');
    } else if (role == 'guard') {
      Navigator.pushReplacementNamed(context, '/guard');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            AnimatedOpacity(
              duration: const Duration(seconds: 1),
              opacity: _logoOpacity,
              curve: Curves.easeOut,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.apartment_rounded,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // App Name
            AnimatedOpacity(
              duration: const Duration(seconds: 1),
              opacity: _appOpacity,
              curve: Curves.easeOut,
              child: Column(
                children: [
                   Text(
                    "Building Management",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  Text(
                    "System",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey,
                          letterSpacing: 2,
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 60),

            // User Name
            if (_showUser)
              AnimatedOpacity(
                duration: const Duration(seconds: 1),
                opacity: _userOpacity,
                curve: Curves.easeOut,
                child: Column(
                  children: [
                    Text(
                      "Welcome back,",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _userName!,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
