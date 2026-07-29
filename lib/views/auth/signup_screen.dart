import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/validators.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../widgets/common/loading_overlay.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtr = TextEditingController();
  final _emailCtr = TextEditingController();
  final _passwordCtr = TextEditingController();

  @override
  void dispose() {
    _nameCtr.dispose();
    _emailCtr.dispose();
    _passwordCtr.dispose();
    super.dispose();
  }

  Future<void> _signUp(AuthViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await vm.signUp(
      name: _nameCtr.text.trim(),
      email: _emailCtr.text.trim(),
      password: _passwordCtr.text,
    );

    if (!mounted) return;

    if (success) {
      // Navigate to verification screen after successful signup
      Navigator.of(context).pushReplacementNamed('/verifyEmail');
    } else if (vm.hasError) {
      AppSnackbar.showError(context, vm.errorMessage ?? AppStrings.genericError);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, vm, _) {
        return LoadingOverlay(
          isLoading: vm.isLoading,
          message: 'Creating account…',
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),

                      // Back button
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Title
                      const Text(
                        AppStrings.createAccount,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Join Circle Vault and start saving together.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Full name
                      CustomTextField(
                        label: AppStrings.fullName,
                        controller: _nameCtr,
                        hint: AppStrings.fullNameHint,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        validator: Validators.validateName,
                      ),
                      const SizedBox(height: 18),

                      // Email
                      CustomTextField(
                        label: AppStrings.email,
                        controller: _emailCtr,
                        hint: AppStrings.emailHint,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.email_outlined),
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                        ],
                        validator: Validators.validateEmail,
                      ),
                      const SizedBox(height: 18),

                      // Password
                      CustomTextField(
                        label: AppStrings.password,
                        controller: _passwordCtr,
                        hint: AppStrings.passwordHint,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        validator: Validators.validatePassword,
                        onFieldSubmitted: (_) => _signUp(vm),
                      ),
                      const SizedBox(height: 16),

                      // Password requirements hint
                      const Text(
                        'Password must be at least 6 characters',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit
                      CustomButton(
                        label: AppStrings.signup,
                        onPressed: vm.isLoading ? null : () => _signUp(vm),
                        isLoading: vm.isLoading,
                      ),
                      const SizedBox(height: 24),

                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            AppStrings.alreadyHaveAccount,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context)
                                .pushReplacementNamed('/login'),
                            child: const Text(
                              AppStrings.loginLink,
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}