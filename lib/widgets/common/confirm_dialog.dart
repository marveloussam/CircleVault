import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'custom_button.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  ButtonVariant confirmVariant = ButtonVariant.primary,
  IconData? icon,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _ConfirmSheet(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      confirmVariant: confirmVariant,
      icon: icon,
    ),
  );
  return result ?? false;
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.confirmVariant,
    this.icon,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final ButtonVariant confirmVariant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          if (icon != null) ...[
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: confirmVariant == ButtonVariant.danger
                    ? AppColors.errorLight
                    : AppColors.accentLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: confirmVariant == ButtonVariant.danger
                    ? AppColors.error
                    : AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
          ],

          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          CustomButton(
            label: confirmLabel,
            onPressed: () => Navigator.of(context).pop(true),
            variant: confirmVariant,
          ),
          const SizedBox(height: 10),
          CustomButton(
            label: cancelLabel,
            onPressed: () => Navigator.of(context).pop(false),
            variant: ButtonVariant.ghost,
          ),
        ],
      ),
    );
  }
}
