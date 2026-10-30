import 'package:circlevault/views/auth/email_verification_screen.dart';
import 'package:circlevault/views/auth/forgot_password.dart';
import 'package:circlevault/views/payment/wallet_screen.dart';
import 'package:circlevault/views/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_colors.dart';
import 'repositories/ai_advisory_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/circle_repository.dart';
import 'repositories/payment_repository.dart';
import 'repositories/transaction_repository.dart';
import 'repositories/user_repository.dart';
import 'viewmodels/ai_advisory_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/circle_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/ledger_viewmodel.dart';
import 'viewmodels/payment_viewmodel.dart';
import 'views/advisory/ai_tips_screen.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/otp_screen.dart';
import 'views/auth/signup_screen.dart';
import 'views/auth/splash_screen.dart';
import 'views/circle/circle_detail_screen.dart';
import 'views/circle/circle_list_screen.dart';
import 'views/circle/create_circle_screen.dart';
import 'views/home/home_screen.dart';
import 'views/ledger/ledger_screen.dart';
import 'views/main/main_shell.dart';
import 'views/payment/add_card_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo    = AuthRepository();
    final userRepo    = UserRepository();
    final circleRepo  = CircleRepository();
    final txRepo      = TransactionRepository();
    final paymentRepo = PaymentRepository();
    final aiRepo      = AiAdvisoryRepository();

    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepo),
        Provider<UserRepository>.value(value: userRepo),
        Provider<CircleRepository>.value(value: circleRepo),
        Provider<TransactionRepository>.value(value: txRepo),
        Provider<PaymentRepository>.value(value: paymentRepo),
        Provider<AiAdvisoryRepository>.value(value: aiRepo),

        ChangeNotifierProvider<AuthViewModel>(
          create: (_) => AuthViewModel(authRepository: authRepo),
        ),
        ChangeNotifierProvider<HomeViewModel>(
          create: (_) => HomeViewModel(
            userRepository: userRepo,
            circleRepository: circleRepo,
            transactionRepository: txRepo,
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => CircleViewModel(
            circleRepository: ctx.read<CircleRepository>(),
            userRepository: ctx.read<UserRepository>(), // ← add this
          ),
        ),
        ChangeNotifierProvider<LedgerViewModel>(
          create: (_) => LedgerViewModel(transactionRepository: txRepo),
        ),
        ChangeNotifierProvider<PaymentViewModel>(
          create: (_) => PaymentViewModel(
            paymentRepository: paymentRepo,
          ),
        ),
        ChangeNotifierProvider<AiAdvisoryViewModel>(
          create: (_) => AiAdvisoryViewModel(
            aiRepository: aiRepo,
            transactionRepository: txRepo,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Circle Vault',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        initialRoute: '/splash',
        routes: {
          '/splash'        : (_) => const SplashScreen(),
          '/login'         : (_) => const LoginScreen(),
          '/signup'        : (_) => const SignupScreen(),
          // '/otp'           : (_) => const OtpScreen(),
          '/forgotPassword': (_) => const ForgotPasswordScreen(),
          '/home': (_) => const MainShell(),
          '/circles'       : (_) => const CircleListScreen(),
          '/createCircle'  : (_) => const CreateCircleScreen(),
          '/circle'        : (_) => const CircleDetailScreen(),
          '/ledger'        : (_) => const LedgerScreen(),
          '/addCard'       : (_) => const AddCardScreen(),
          '/tips'          : (_) => const AiTipsScreen(),
          '/wallet'       : (_) => const WalletScreen(),
          '/verifyEmail': (context) => const EmailVerificationScreen(),
          '/profile'       : (_) => const ProfileScreen(),
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    // Set status bar to dark icons on light backgrounds
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.navBackground,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // ── Color scheme ────────────────────────────────────────────────────────
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnTeal,
        secondary: AppColors.primaryLight,
        onSecondary: AppColors.textOnTeal,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.border,
      ),

      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',

      // ── AppBar ──────────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.shadow,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        actionsIconTheme: IconThemeData(color: AppColors.textSecondary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          fontFamily: 'Roboto',
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),

      // ── Elevated button (primary CTA) ────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnTeal,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
          disabledForegroundColor: Colors.white54,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
          minimumSize: const Size(double.infinity, 52),
        ),
      ),

      // ── Outlined button ──────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          minimumSize: const Size(double.infinity, 52),
        ),
      ),

      // ── Text button ──────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),

      // ── Input decoration ─────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: AppColors.textHint,
          fontSize: 15,
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      ),

      // ── Card ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: AppColors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.divider, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Bottom navigation ────────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.navBackground,
        selectedItemColor: AppColors.navActive,
        unselectedItemColor: AppColors.navInactive,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 11),
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      // ── FAB ──────────────────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.fabColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // ── Divider ──────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // ── Chip ────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.accentLight,
        labelStyle: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),

      // ── SnackBar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 4,
      ),

      // ── Progress indicator ───────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.progressTrack,
        circularTrackColor: AppColors.progressTrack,
      ),

      // ── Switch / checkbox ────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textHint,
        ),
        trackColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
              ? AppColors.primaryLight.withOpacity(0.4)
              : AppColors.border,
        ),
      ),

      // ── Text theme ───────────────────────────────────────────────────────
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 32),
        displayMedium: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 26),
        headlineLarge: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 22),
        headlineMedium: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18),
        headlineSmall: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16),
        titleLarge: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15),
        titleMedium: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14),
        bodyLarge: TextStyle(
            color: AppColors.textPrimary, fontSize: 15, height: 1.5),
        bodyMedium: TextStyle(
            color: AppColors.textSecondary, fontSize: 13, height: 1.5),
        bodySmall: TextStyle(
            color: AppColors.textHint, fontSize: 12, height: 1.4),
        labelLarge: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13),
        labelSmall: TextStyle(
            color: AppColors.textHint,
            fontSize: 10,
            letterSpacing: 0.5),
      ),
    );
  }
}
