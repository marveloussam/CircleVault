import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/error_snackbar.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isChecking = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    // Start checking periodically in the background
    _startVerificationCheck();
  }

  void _startVerificationCheck() {
    // Check immediately
    _checkVerification();

    // Then check every 5 seconds for 2 minutes
    int attempts = 0;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return false;
      attempts++;
      if (attempts >= 24) return false; // 2 minutes max
      await _checkVerification();
      return !_isChecking; // Stop if verification is complete
    });
  }

  Future<void> _checkVerification() async {
    if (_isChecking) return;

    _isChecking = true;
    // Don't call setState here to avoid UI flicker

    try {
      final vm = context.read<AuthViewModel>();
      final isVerified = await vm.checkEmailVerified();

      if (!mounted) return;

      if (isVerified) {
        // Use a small delay to allow the verification to register
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
        }
      }
    } catch (e) {
      // Silent fail - don't show errors for background checks
      debugPrint('Background verification check failed: $e');
    } finally {
      _isChecking = false;
    }
  }

  Future<void> _resendEmail() async {
    if (_isResending) return;

    setState(() => _isResending = true);

    try {
      final vm = context.read<AuthViewModel>();
      final success = await vm.resendVerificationEmail();

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email resent. Please check your inbox.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        AppSnackbar.showError(
          context,
          vm.errorMessage ?? AppStrings.genericError,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          'Failed to resend verification email. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _manualCheck() async {
    if (_isChecking) return;

    // Show a loading indicator only for manual check
    setState(() => _isChecking = true);

    try {
      final vm = context.read<AuthViewModel>();
      final isVerified = await vm.checkEmailVerified();

      if (!mounted) return;

      if (isVerified) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
      } else {
        // Show a brief message that it's still not verified
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email not verified yet. Please check your inbox.'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          'Failed to check verification status. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.email_outlined,
                  color: AppColors.accent,
                  size: 64,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                'Verify Your Email',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              // Description - using Consumer for email display
              Consumer<AuthViewModel>(
                builder: (context, vm, _) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'We\'ve sent a verification link to\n${vm.currentUser?.email ?? 'your email'}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: AppColors.accent, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Open the email we sent you',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: AppColors.accent, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Click the verification link in the email',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: AppColors.accent, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Return to this app and you\'ll be automatically logged in',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Resend button
              CustomButton(
                label: 'Resend Verification Email',
                onPressed: _isResending || _isChecking ? null : _resendEmail,
                isLoading: _isResending,
                // isOutlined: true,
              ),
              const SizedBox(height: 16),

              // Check now button
              CustomButton(
                label: 'I\'ve Verified My Email',
                onPressed: _isChecking || _isResending ? null : _manualCheck,
                isLoading: _isChecking,
              ),
              const SizedBox(height: 16),

              // Logout button
              TextButton(
                onPressed: _isResending || _isChecking
                    ? null
                    : () async {
                  final vm = context.read<AuthViewModel>();
                  await vm.logout();
                  if (mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                },
                child: const Text(
                  'Use a different account',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Status indicator (shows when checking in background)
              if (_isChecking)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accent,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Checking for verification...',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}