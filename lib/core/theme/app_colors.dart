import 'package:flutter/material.dart';

/// HealthBase color system.
/// 
/// Designed to evoke calm, clinical trustworthiness, clarity, and precision.
/// All text and interactive color pairings achieve WCAG AA contrast compliance.
class AppColors {
  const AppColors._();

  // Primary Clinical Teals
  static const Color primary50 = Color(0xFFF0FDF4);
  static const Color primary100 = Color(0xFFDCFCE7);
  static const Color primary500 = Color(0xFF0F766E); // Main primary (Teal)
  static const Color primary600 = Color(0xFF0D6861);
  static const Color primary700 = Color(0xFF0A514B);
  static const Color primaryDark = Color(0xFF14B8A6);

  // Secondary Calm Accents
  static const Color secondary500 = Color(0xFF2563EB); // Royal Blue
  static const Color secondaryLight = Color(0xFF3B82F6);

  // Status & Health Indicators
  static const Color statusStable = Color(0xFF10B981); // Emerald
  static const Color statusIncreased = Color(0xFFF59E0B); // Amber
  static const Color statusDecreased = Color(0xFF06B6D4); // Cyan
  static const Color statusUrgent = Color(0xFFEF4444); // Crimson
  static const Color statusSyncing = Color(0xFF8B5CF6); // Purple

  // Neutral Scales (Light Mode)
  static const Color neutral50 = Color(0xFFF8FAFC);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral900 = Color(0xFF0F172A);

  // Surfaces & Backgrounds
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceSubtleLight = Color(0xFFF1F5F9);

  // Dark Mode Surfaces
  static const Color backgroundDark = Color(0xFF0B132B);
  static const Color surfaceDark = Color(0xFF1C2541);
  static const Color surfaceSubtleDark = Color(0xFF222F55);
}
