import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary ───────────────────────────────────────────────────────────────
  static const Color primary        = Color(0xFF1DB954);
  static const Color primaryDark    = Color(0xFF17963F);
  static const Color primaryLight   = Color(0xFF4CD980);
  static const Color primarySurface = Color(0x1F1DB954); // ~12% opacity

  // ── Backgrounds ───────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0D0D0D);
  static const Color darkSurface    = Color(0xFF1C1C1E);
  static const Color darkCard       = Color(0xFF1C1C1E);
  static const Color darkElevated   = Color(0xFF2C2C2E);
  static const Color darkBorder     = Color(0x14FFFFFF); // 8% white

  // ── Light mode (kept for toggle support) ─────────────────────────────────
  static const Color lightBackground    = Color(0xFFF2F2F7);
  static const Color lightSurface       = Color(0xFFFFFFFF);
  static const Color lightCard          = Color(0xFFFFFFFF);
  static const Color lightBorder        = Color(0xFFE5E5EA);
  static const Color textDark           = Color(0xFF1C1C1E);
  static const Color textSecondaryDark  = Color(0xFF636366);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFFFFFFFF);
  static const Color textSecondary  = Color(0xFF8E8E93);
  static const Color textMuted      = Color(0xFF636366);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success    = Color(0xFF1DB954);
  static const Color error      = Color(0xFFFF3B30);
  static const Color warning    = Color(0xFFFF9F0A);
  static const Color info       = Color(0xFF0A84FF);
  static const Color accent     = Color(0xFFFF9F0A);
  static const Color secondary  = Color(0xFF0A84FF);
  static const Color gold       = Color(0xFFFFD60A);

  // ── Sport colors ──────────────────────────────────────────────────────────
  static const Color football   = Color(0xFF1DB954);
  static const Color padel      = Color(0xFF0A84FF);
  static const Color basketball = Color(0xFFFF9F0A);
  static const Color tennis     = Color(0xFFFFD60A);

  // ── Rank colors ───────────────────────────────────────────────────────────
  static const Color rankGold   = Color(0xFFFFD60A);
  static const Color rankSilver = Color(0xFFAEAEB2);
  static const Color rankBronze = Color(0xFFCD7F32);

  // ── Tournament status ─────────────────────────────────────────────────────
  static const Color upcomingColor  = Color(0xFF0A84FF);
  static const Color liveColor      = Color(0xFFFF3B30);
  static const Color finishedColor  = Color(0xFF636366);
  static const Color cancelledColor = Color(0xFFFF9F0A);

  // ── Payment providers ─────────────────────────────────────────────────────
  static const Color vodafoneColor = Color(0xFFE60000);
  static const Color fawryColor    = Color(0xFFF5A623);
  static const Color cardColor     = Color(0xFF1565C0);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0D2818), Color(0xFF1DB954)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF000000), Color(0xFF0D0D0D), Color(0xFF1A2E1A)],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );
}
