import 'package:flutter/material.dart';

import 'package:foodpilot/app/theme/app_colors.dart';
import 'package:foodpilot/app/theme/tokens.dart';

/// Nama keluarga font di pubspec.yaml.
const String kFontFamily = 'PlusJakartaSans';

/// Gaya teks yang tidak punya padanan peran di `TextTheme` Material.
abstract final class AppType {
  /// Semua angka wajib tabular: tiap digit selebar digit lain, jadi total yang
  /// berubah tiap tap tidak terlihat bergoyang.
  static const List<FontFeature> tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  /// Angka besar, subjek utama layar.
  static const TextStyle bigNumber = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 46,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.6,
    height: 1.1,
    fontFeatures: tabular,
  );

  /// Label tab aktif di tab bar.
  static const TextStyle tabLabel = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    fontFeatures: tabular,
  );
}

/// Tema terang dan gelap, dibangun dari token (CONTEXT.md bagian 7).
///
/// Padanannya di web: `globals.css` milik shadcn. Widget bawaan Material
/// (tombol, input, switch, SnackBar) membaca `ColorScheme` dan `TextTheme`,
/// sama seperti komponen shadcn membaca `--primary` dan `--background`.
abstract final class AppTheme {
  static final ThemeData light = _build(AppColors.light, Brightness.light);
  static final ThemeData dark = _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    // Dibuat manual, bukan ColorScheme.fromSeed, supaya tidak ada warna
    // turunan yang tidak kita pilih.
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.ink,
      onPrimary: c.onInk,
      secondary: c.ink,
      onSecondary: c.onInk,
      secondaryContainer: c.border,
      onSecondaryContainer: c.text,
      error: c.danger,
      onError: c.onDanger,
      surface: c.surface,
      onSurface: c.text,
      surfaceContainerHighest: c.border,
      onSurfaceVariant: c.textMuted,
      outline: c.textMuted,
      outlineVariant: c.border,
      inverseSurface: c.ink,
      onInverseSurface: c.onInk,
      surfaceTint: Colors.transparent,
    );

    return ThemeData(
      colorScheme: scheme,
      fontFamily: kFontFamily,
      textTheme: _textTheme(c),
      scaffoldBackgroundColor: c.background,
      extensions: <ThemeExtension<dynamic>>[c],
      appBarTheme: AppBarThemeData(
        backgroundColor: c.background,
        foregroundColor: c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.background,
        modalBackgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s16,
          vertical: AppSpace.s12,
        ),
        border: _inputBorder(c.border),
        enabledBorder: _inputBorder(c.border),
        focusedBorder: _inputBorder(c.ink, width: 1.6),
        errorBorder: _inputBorder(c.danger),
        focusedErrorBorder: _inputBorder(c.danger, width: 1.6),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.ink,
        contentTextStyle: TextStyle(fontFamily: kFontFamily, color: c.onInk),
        actionTextColor: c.onInk,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        ),
      ),
      listTileTheme: ListTileThemeData(iconColor: c.text),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: c.textMuted,
        collapsedIconColor: c.textMuted,
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.sheet)),
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// Pemetaan gaya di CONTEXT.md ke peran `TextTheme` Material.
  static TextTheme _textTheme(AppColors c) {
    TextStyle style(
      double size,
      FontWeight weight,
      double height, [
      Color? color,
    ]) {
      return TextStyle(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: 0,
        color: color,
        fontFeatures: AppType.tabular,
      );
    }

    return TextTheme(
      headlineSmall: style(24, FontWeight.w600, 1.25, c.text), // Judul
      titleLarge: style(18, FontWeight.w600, 1.3, c.text), // Subjudul
      bodyLarge: style(16, FontWeight.w400, 1.5, c.text), // Isi
      labelLarge: style(16, FontWeight.w600, 1.25), // Tombol
      bodyMedium: style(14, FontWeight.w400, 1.45, c.text), // Keterangan
      bodySmall: style(12, FontWeight.w400, 1.35, c.textMuted), // Label kecil
    );
  }
}
