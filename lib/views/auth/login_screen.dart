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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtr = TextEditingController();
  final _passwordCtr = TextEditingController();

  @override
  void dispose() {
    _emailCtr.dispose();
    _passwordCtr.dispose();
    super.dispose();
  }

  Future<void> _login(AuthViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await vm.signIn(
      email: _emailCtr.text.trim(),
      password: _passwordCtr.text,
    );

    if (!mounted) return;

    if (success) {
      // Check if email is verified
      final isVerified = await vm.checkEmailVerified();
      if (!mounted) return;

      if (isVerified) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
      } else {
        // Navigate to verification screen
        Navigator.of(context).pushReplacementNamed('/verifyEmail');
      }
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
          message: 'Signing in…',
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
                      const SizedBox(height: 48),

                      // Logo mark (small)
                      Center(
                        child: Image.asset("assets/icon/icon.png"),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      const Center(
                        child: Text(
                          AppStrings.welcomeBack,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Center(
                        child: Text(
                          AppStrings.loginSubtitle,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

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
                        onFieldSubmitted: (_) => _login(vm),
                      ),
                      const SizedBox(height: 10),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context)
                              .pushNamed('/forgotPassword'),
                          child: const Text(
                            AppStrings.forgotPassword,
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Login button
                      CustomButton(
                        label: AppStrings.login,
                        onPressed: vm.isLoading ? null : () => _login(vm),
                        isLoading: vm.isLoading,
                      ),
                      const SizedBox(height: 24),

                      // Signup link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            AppStrings.noAccount,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context)
                                .pushReplacementNamed('/signup'),
                            child: const Text(
                              AppStrings.signupLink,
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
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