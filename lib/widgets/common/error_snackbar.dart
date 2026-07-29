import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

abstract class AppSnackbar {
  static void showError(BuildContext context, String message) {
    _show(context,
        message: message,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline_rounded);
  }

  static void showSuccess(BuildContext context, String message) {
    _show(context,
        message: message,
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_outline_rounded);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context,
        message: message,
        backgroundColor: AppColors.primary,
        icon: Icons.info_outline_rounded);
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        duration: duration,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
