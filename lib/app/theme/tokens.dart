import 'package:flutter/painting.dart';

/// Nilai mentah sistem desain (CONTEXT.md bagian 7).
///
/// Warna di sini hanya dibaca oleh `app_colors.dart`. Widget mengambil warna
/// lewat `context.colors`, tidak pernah dari file ini dan tidak pernah sebagai
/// `Color(0x...)` literal. Spasi, radius, dan ukuran boleh dipakai langsung.
abstract final class LightTokens {
  static const Color ink = Color(0xFF1C1A17);
  static const Color onInk = Color(0xFFFAF8F5);
  static const Color background = Color(0xFFFAF8F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE8E3DC);
  static const Color text = Color(0xFF1C1A17);
  static const Color textMuted = Color(0xFF6B655C);
  static const Color success = Color(0xFF157F48);
  static const Color onSuccess = Color(0xFFFAF8F5);
  static const Color warning = Color(0xFFC2740A);
  static const Color onWarning = Color(0xFF1C1A17);
  static const Color danger = Color(0xFFC0392F);
  static const Color onDanger = Color(0xFFFAF8F5);
  static const Color accent = Color(0xFF3A48A8);
}

abstract final class DarkTokens {
  static const Color ink = Color(0xFFF5F1EA);
  static const Color onInk = Color(0xFF191714);
  static const Color background = Color(0xFF191714);
  static const Color surface = Color(0xFF23201C);
  static const Color border = Color(0xFF37322C);
  static const Color text = Color(0xFFF5F1EA);
  static const Color textMuted = Color(0xFFA39C92);
  static const Color success = Color(0xFF2FA968);
  static const Color onSuccess = Color(0xFF191714);
  static const Color warning = Color(0xFFE0952C);
  static const Color onWarning = Color(0xFF191714);
  static const Color danger = Color(0xFFE0645A);
  static const Color onDanger = Color(0xFF191714);
  static const Color accent = Color(0xFF6C78D8);
}

/// Skala spasi: 4, 8, 12, 16, 22, 24, 32, 48.
abstract final class AppSpace {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s22 = 22;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;
}

abstract final class AppRadius {
  static const double card = 20;
  static const double sheet = 26;
}

abstract final class AppSize {
  /// Target sentuh minimum.
  static const double minTouch = 44;

  /// Tinggi pil tab bar.
  static const double tabBarHeight = 64;

  /// Diameter tombol catat di atas tab bar.
  static const double recordButton = 46;

  /// Jarak antara tombol catat dan pil.
  static const double recordButtonGap = 12;

  /// Tinggi pil aksi di layar level 2.
  static const double actionPillHeight = 56;
}
