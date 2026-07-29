import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum ButtonVariant { primary, secondary, outlined, danger, ghost }

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.fullWidth = true,
    this.height = 52.0,
    this.borderRadius = 12.0,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonVariant variant;
  final IconData? icon;
  final bool fullWidth;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    Widget content = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == ButtonVariant.outlined ||
                        variant == ButtonVariant.ghost
                    ? AppColors.primary
                    : Colors.white,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          );

    Widget button = switch (variant) {
      ButtonVariant.primary   => _Primary(content, onPressed: isDisabled ? null : onPressed, h: height, r: borderRadius),
      ButtonVariant.secondary => _Secondary(content, onPressed: isDisabled ? null : onPressed, h: height, r: borderRadius),
      ButtonVariant.outlined  => _Outlined(content, onPressed: isDisabled ? null : onPressed, h: height, r: borderRadius),
      ButtonVariant.danger    => _Danger(content, onPressed: isDisabled ? null : onPressed, h: height, r: borderRadius),
      ButtonVariant.ghost     => _Ghost(content, onPressed: isDisabled ? null : onPressed, h: height, r: borderRadius),
    };

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class _Primary extends StatelessWidget {
  const _Primary(this.child, {this.onPressed, required this.h, required this.r});
  final Widget child;
  final VoidCallback? onPressed;
  final double h, r;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: h,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary.withOpacity(0.35),
            disabledForegroundColor: Colors.white54,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(r)),
          ),
          child: child,
        ),
      );
}

class _Secondary extends StatelessWidget {
  const _Secondary(this.child, {this.onPressed, required this.h, required this.r});
  final Widget child;
  final VoidCallback? onPressed;
  final double h, r;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: h,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentLight,
            foregroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.accentLight.withOpacity(0.5),
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(r)),
          ),
          child: child,
        ),
      );
}

class _Outlined extends StatelessWidget {
  const _Outlined(this.child, {this.onPressed, required this.h, required this.r});
  final Widget child;
  final VoidCallback? onPressed;
  final double h, r;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: h,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(
              color: onPressed == null
                  ? AppColors.primary.withOpacity(0.3)
                  : AppColors.primary,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(r)),
          ),
          child: child,
        ),
      );
}

class _Danger extends StatelessWidget {
  const _Danger(this.child, {this.onPressed, required this.h, required this.r});
  final Widget child;
  final VoidCallback? onPressed;
  final double h, r;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: h,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.error.withOpacity(0.35),
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(r)),
          ),
          child: child,
        ),
      );
}

class _Ghost extends StatelessWidget {
  const _Ghost(this.child, {this.onPressed, required this.h, required this.r});
  final Widget child;
  final VoidCallback? onPressed;
  final double h, r;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: h,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(r)),
          ),
          child: child,
        ),
      );
}
