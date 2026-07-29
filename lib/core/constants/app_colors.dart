import 'package:flutter/material.dart';

abstract class AppColors {
  // ── Brand gradient (splash + onboarding backgrounds) ──────────────────────
  static const Color gradientStart = Color(0xFF0A7B6E); // deep teal
  static const Color gradientMid   = Color(0xFF0AADA0); // mid teal
  static const Color gradientEnd   = Color(0xFF00C4B4); // bright cyan-teal

  // ── Primary teal (buttons, active states, accents) ─────────────────────────
  static const Color primary       = Color(0xFF1BAF8C); // main teal-green CTA
  static const Color primaryDark   = Color(0xFF158A6E); // pressed / hover state
  static const Color primaryLight  = Color(0xFF2DDBB8); // lighter teal highlight

  // ── Backgrounds ────────────────────────────────────────────────────────────
  // Screens use a light grey app background with white cards
  static const Color background    = Color(0xFFF4F6F9); // light grey scaffold
  static const Color surface       = Color(0xFFFFFFFF); // white cards
  static const Color surfaceAlt    = Color(0xFFF0F4F8); // slightly tinted surface
  static const Color onboardingBg  = Color(0xFF0A9688); // onboarding solid bg

  // ── Wallet hero card (screen 7 teal card) ─────────────────────────────────
  static const Color walletCardStart = Color(0xFF0D9B8A);
  static const Color walletCardEnd   = Color(0xFF00C4B4);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF1A1A2A); // near-black
  static const Color textSecondary = Color(0xFF6B7080); // medium grey
  static const Color textHint      = Color(0xFFAEB5C0); // light grey placeholder
  static const Color textOnTeal    = Color(0xFFFFFFFF); // white text on teal
  static const Color textOnGradient= Color(0xFFFFFFFF); // white on gradient BG

  // ── Interactive / accent ───────────────────────────────────────────────────
  static const Color accent        = Color(0xFF1BAF8C); // same as primary
  static const Color accentLight   = Color(0xFFE6F9F5); // teal tint for chips/badges
  static const Color link          = Color(0xFF1BAF8C); // tappable links

  // ── Status ─────────────────────────────────────────────────────────────────
  static const Color success       = Color(0xFF00C853); // money in / positive
  static const Color successLight  = Color(0xFFE6FAF0);
  static const Color error         = Color(0xFFFF4757); // money out / negative
  static const Color errorLight    = Color(0xFFFFECEE);
  static const Color warning       = Color(0xFFFFB300);
  static const Color warningLight  = Color(0xFFFFF8E1);
  static const Color info          = Color(0xFF2196F3);
  static const Color infoLight     = Color(0xFFE3F2FD);

  // ── Transaction type colours ───────────────────────────────────────────────
  static const Color contribution  = Color(0xFF00C853); // green — money in
  static const Color payout        = Color(0xFF1BAF8C); // teal — ROSCA payout
  static const Color fee           = Color(0xFFFF4757); // red — deductions
  static const Color refund        = Color(0xFF2196F3); // blue

  // ── UI elements ────────────────────────────────────────────────────────────
  static const Color divider       = Color(0xFFECEFF4); // very light separator
  static const Color border        = Color(0xFFDDE2EA); // input/card border
  static const Color shadow        = Color(0x14000000); // 8% black shadow
  static const Color shadowMedium  = Color(0x1F000000); // 12% black shadow

  // ── Bottom nav ─────────────────────────────────────────────────────────────
  static const Color navBackground = Color(0xFFFFFFFF);
  static const Color navActive     = Color(0xFF1BAF8C);
  static const Color navInactive   = Color(0xFFAEB5C0);
  static const Color fabColor      = Color(0xFF1BAF8C);

  // ── Phone prefix pill (screen 3) ───────────────────────────────────────────
  static const Color phonePill     = Color(0xFF1BAF8C);
  static const Color phonePillText = Color(0xFFFFFFFF);

  // ── Active group badge ─────────────────────────────────────────────────────
  static const Color activeBadge     = Color(0xFFE6F9F5);
  static const Color activeBadgeText = Color(0xFF1BAF8C);

  // ── Progress bar ───────────────────────────────────────────────────────────
  static const Color progressTrack = Color(0xFFECEFF4);
  static const Color progressFill  = Color(0xFF1BAF8C);

  // ── Shimmer (light mode) ───────────────────────────────────────────────────
  static const Color shimmerBase      = Color(0xFFE8ECF0);
  static const Color shimmerHighlight = Color(0xFFF5F7FA);

  // ── Gradient helpers ───────────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientMid, gradientEnd],
  );

  static const LinearGradient walletGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [walletCardStart, walletCardEnd],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientStart, gradientEnd],
  );
}
