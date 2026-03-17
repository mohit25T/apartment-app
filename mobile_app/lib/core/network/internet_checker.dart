import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class InternetChecker {
  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static OverlayEntry? _overlay;

  static void startListening(GlobalKey<NavigatorState> navigatorKey) {

    _subscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {

      final hasInternet = await _checkInternet();

      if (!hasInternet) {
        _showOverlay(navigatorKey);
      } else {
        _hideOverlay();
      }
    });

    /// Check once when app starts
    _checkInternet().then((hasInternet) {
      if (!hasInternet) {
        _showOverlay(navigatorKey);
      }
    });
  }

  static Future<bool> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup("google.com");
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static void _showOverlay(GlobalKey<NavigatorState> navigatorKey) {

    if (_overlay != null) return;

    final overlayState = navigatorKey.currentState?.overlay;

    if (overlayState == null) return;

    _overlay = OverlayEntry(
      builder: (_) => Material(
        color: Colors.black54,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off, size: 60, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  "No Internet Connection",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  "Please check your internet connection.",
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlayState.insert(_overlay!);
  }

  static void _hideOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  static void stopListening() {
    _subscription?.cancel();
  }
}
