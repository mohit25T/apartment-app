import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/sos_alarm_service.dart';

class GlobalPopup extends StatelessWidget {
  final String title;
  final String message;
  final String type; // SOS, SUCCESS, REJECT
  final VoidCallback? onDismiss;

  const GlobalPopup({
    super.key,
    required this.title,
    required this.message,
    required this.type,
    this.onDismiss,
  });

  static void show(BuildContext context, {
    required String title,
    required String message,
    required String type,
  }) {
    showDialog(
      context: context,
      barrierDismissible: type != "SOS", // SOS must be stopped explicitly
      builder: (context) => GlobalPopup(
        title: title,
        message: message,
        type: type,
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSos = type == "SOS";
    final isSuccess = type == "SUCCESS";

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Theme.of(context).cardColor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (isSos ? AppColors.error : (isSuccess ? Colors.green : Colors.orange)).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSos ? Icons.warning_rounded : (isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded),
                size: 48,
                color: isSos ? AppColors.error : (isSuccess ? Colors.green : Colors.orange),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 12),
            
            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 30),
            
            // Action Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () async {
                  if (isSos) {
                    await SOSAlarmService.stopAlarm();
                  }
                  if (onDismiss != null) onDismiss!();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSos ? AppColors.error : (isSuccess ? Colors.green : AppColors.primary),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isSos ? "STOP ALARM" : "OK",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
