import 'package:flutter/material.dart';

/// Dark Onyx Neumorphism — Design System Color Tokens with Rich Accents
class AppColors {
  AppColors._();

  // ── Surface Layers ──────────────────────────────────────────────
  static const Color surfaceCanvas         = Color(0xFF121316); // canvas utama
  static const Color surfaceDim            = Color(0xFF0D0E11); // inset / deepest
  static const Color surfaceContainerLow   = Color(0xFF18191D); // kontainer sekunder
  static const Color surfaceContainer      = Color(0xFF1C1D22); // kartu neumorphic standar
  static const Color surfaceContainerHigh  = Color(0xFF25262C); // modal / floating
  static const Color surfaceBright         = Color(0xFF38393C); // border pemisah

  // ── Text ────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF4F4F5); // judul, nilai utama
  static const Color textSecondary = Color(0xFF9CA3AF); // label, subteks
  static const Color textMuted     = Color(0xFF52525B); // placeholder, timestamp

  // ── Accent (Monokrom & Highlights) ──────────────────────────────
  static const Color accentWhite = Color(0xFFFFFFFF); // CTA utama, active indicator
  static const Color accentBlack = Color(0xFF000000); // teks pada tombol putih

  // ── Vibrant Functional / Semantic Colors ────────────────────────
  static const Color positive      = Color(0xFF10B981); // Emerald Green (Income / Pemasukan)
  static const Color positiveLight = Color(0xFF34D399);
  static const Color negative      = Color(0xFFF43F5E); // Crimson Rose (Expense / Pengeluaran)
  static const Color negativeLight = Color(0xFFFB7185);

  // ── Wallet & Payment Accents ───────────────────────────────────
  static const Color cardColor     = Color(0xFF6366F1); // Indigo / Violet (Kredit / Kartu)
  static const Color cardGradientEnd = Color(0xFF4F46E5);
  static const Color cashColor     = Color(0xFF10B981); // Emerald (Cash / Tunai)
  static const Color cashGradientEnd = Color(0xFF059669);
  static const Color goldAccent    = Color(0xFFF59E0B); // Amber / Gold
  static const Color cyanAccent    = Color(0xFF06B6D4); // Cyan / Blue

  // ── Palette for Charts ──────────────────────────────────────────
  static const List<Color> chartPalette = [
    Color(0xFF10B981), // Emerald
    Color(0xFF6366F1), // Indigo
    Color(0xFFF59E0B), // Amber
    Color(0xFFF43F5E), // Rose
    Color(0xFF06B6D4), // Cyan
    Color(0xFFA855F7), // Purple
    Color(0xFFF97316), // Orange
    Color(0xFF38BDF8), // Sky
  ];

  // ── Neumorphic Shadow ───────────────────────────────────────────
  // Extruded (Raised Card): cahaya kiri-atas 135°
  static const Color shadowLight = Color(0x09FFFFFF); // rgba(255,255,255,0.035)
  static const Color shadowDark  = Color(0xA6000000); // rgba(0,0,0,0.65)

  // Floating element shadow (FAB, modal)
  static const Color shadowLightFloat = Color(0x0DFFFFFF); // rgba(255,255,255,0.05)
  static const Color shadowDarkFloat  = Color(0xD9000000); // rgba(0,0,0,0.85)

  // Inset shadow (input, pressed state)
  static const Color shadowInsetDark  = Color(0xB3000000); // rgba(0,0,0,0.7)
  static const Color shadowInsetLight = Color(0x06FFFFFF); // rgba(255,255,255,0.025)

  // ── Backward compatibility aliases ─────────────────────────────
  @Deprecated('Use surfaceCanvas instead')
  static const Color backgroundColor = surfaceCanvas;
  @Deprecated('Use surfaceContainer instead')
  static const Color surfaceColor = surfaceContainer;
  @Deprecated('Use textPrimary instead')
  static const Color textColor = textPrimary;
  @Deprecated('Use accentWhite instead')
  static const Color accentColor = accentWhite;
}
