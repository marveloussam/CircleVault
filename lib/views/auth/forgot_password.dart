import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/validators.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../widgets/common/loading_overlay.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtr = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailCtr.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail(AuthViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await vm.sendPasswordReset(
      email: _emailCtr.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      setState(() => _emailSent = true);
    } else {
      AppSnackbar.showError(context, vm.errorMessage ?? AppStrings.genericError);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, vm, _) {
        return LoadingOverlay(
          isLoading: vm.isLoading,
          message: 'Sending reset email…',
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Reset Password',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your email address and we\'ll send you a link to reset your password.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_emailSent) ...[
                    // Success state
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              color: Colors.green, size: 48),
                          const SizedBox(height: 12),
                          const Text(
                            'Password reset email sent!',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check your email at ${_emailCtr.text} for the reset link.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          CustomButton(
                            label: 'Back to Login',
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Email input form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CustomTextField(
                            label: AppStrings.email,
                            controller: _emailCtr,
                            hint: AppStrings.emailHint,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            prefixIcon: const Icon(Icons.email_outlined),
                            inputFormatters: const [
                              // Remove spaces
                            ],
                            validator: Validators.validateEmail,
                            onFieldSubmitted: (_) => _sendResetEmail(vm),
                          ),
                          const SizedBox(height: 32),
                          CustomButton(
                            label: 'Send Reset Link',
                            onPressed: vm.isLoading ? null : () => _sendResetEmail(vm),
                            isLoading: vm.isLoading,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Back to login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Remember your password? ',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}