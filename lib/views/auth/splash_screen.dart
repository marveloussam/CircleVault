import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../viewmodels/auth_viewmodel.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.read<AuthViewModel>();

    return StreamBuilder<User?>(
      stream: authVM.authStateChanges,
      builder: (context, snapshot) {
        // While waiting for Firebase to respond, show the animated logo
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSplash();
        }

        // Route after a brief logo display
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (snapshot.hasData && snapshot.data != null) {
            Navigator.of(context)
                .pushReplacementNamed('/home');
          } else {
            Navigator.of(context)
                .pushReplacementNamed('/login');
          }
        });

        return _buildSplash();
      },
    );
  }

  Widget _buildSplash() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo mark
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.4),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.2),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '⭕',
                      style: TextStyle(fontSize: 38),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  AppStrings.appName,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  AppStrings.tagline,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.accent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
