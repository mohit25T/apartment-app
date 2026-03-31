import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/api_service.dart';
import '../theme/app_theme.dart';
import '../navigation/navigation_service.dart' as nav_service;

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  /// 🚀 CHECK FOR UPDATES
  Future<void> checkForUpdates({bool silent = true}) async {
    try {
      // 1. Get Local Version Info
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String localVersion = packageInfo.version; // e.g., 1.0.0
      // final String localBuildNumber = packageInfo.buildNumber;

      // 2. Fetch Remote Version Info
      // We assume an endpoint that returns the latest version details
      final response = await ApiService.get("/auth/app-version");
      
      if (response == null || response["version"] == null) return;

      final String remoteVersion = response["version"];
      final bool isMandatory = response["forceUpdate"] ?? false;
      final String? updateUrl = response["updateUrl"];

      // 3. Compare Version (Simple logic: if different, update is available)
      if (_shouldUpdate(localVersion, remoteVersion)) {
        if (nav_service.navigatorKey.currentContext != null) {
          _showUpdateDialog(
            nav_service.navigatorKey.currentContext!,
            remoteVersion,
            isMandatory,
            updateUrl,
          );
        }
      } else if (!silent) {
        // If manual check and no update
        if (nav_service.navigatorKey.currentContext != null) {
          ScaffoldMessenger.of(nav_service.navigatorKey.currentContext!).showSnackBar(
            const SnackBar(content: Text("You are on the latest version!")),
          );
        }
      }
    } catch (e) {
      debugPrint("Update Check Error: $e");
    }
  }

  /// 🍎 HELPERS
  bool _shouldUpdate(String local, String remote) {
    // Simple comparison. For production, use a semantic versioning logic (e.g. 1.0.0 vs 1.0.1)
    return local != remote;
  }

  void _showUpdateDialog(BuildContext context, String version, bool isMandatory, String? updateUrl) {
    showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (context) => WillPopScope(
        onWillPop: () async => !isMandatory,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title
                const Text(
                  "New Update Available",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                // Message
                Text(
                  "A new version ($version) is available. Please update to continue enjoying the best experience.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                ),
                const SizedBox(height: 30),
                
                // Buttons
                Row(
                  children: [
                    if (!isMandatory)
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("LATER"),
                        ),
                      ),
                    
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (updateUrl != null) {
                            final url = Uri.parse(updateUrl);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("UPDATE NOW", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
