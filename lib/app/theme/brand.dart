import 'package:flutter/material.dart';

/// Warna merek dan gaya serif.
///
/// Sengaja dipisah dari [AppColors] supaya penambahan ini tidak menyentuh
/// token yang sudah dipakai layar lain. Dibaca lewat `context.brand`.
@immutable
class BrandPalette {
  const BrandPalette({
    required this.brand,
    required this.onBrand,
    required this.brandTint,
    required this.surfaceMuted,
    required this.successTint,
    required this.warningTint,
    required this.dangerTint,
  });

  /// Warna utama merek. Dipakai sebagai bidang besar, bukan aksen kecil.
  final Color brand;

  /// Teks dan ikon di atas [brand].
  final Color onBrand;

  /// Versi sangat lembut dari [brand], untuk kotak ikon dan latar pasif.
  final Color brandTint;

  final Color surfaceMuted;
  final Color successTint;
  final Color warningTint;
  final Color dangerTint;

  static const light = BrandPalette(
    brand: Color(0xFFB0543A),
    onBrand: Color(0xFFFBF6EE),
    brandTint: Color(0xFFF4E4DB),
    surfaceMuted: Color(0xFFEFE7DA),
    successTint: Color(0xFFDFEDE4),
    warningTint: Color(0xFFF6E8D2),
    dangerTint: Color(0xFFF6DEDB),
  );

  static const dark = BrandPalette(
    brand: Color(0xFFD4785C),
    onBrand: Color(0xFF1F1B16),
    brandTint: Color(0xFF3A2A23),
    surfaceMuted: Color(0xFF2B2620),
    successTint: Color(0xFF1E3329),
    warningTint: Color(0xFF362A18),
    dangerTint: Color(0xFF3A221F),
  );
}

extension BrandContext on BuildContext {
  BrandPalette get brand => Theme.of(this).brightness == Brightness.dark
      ? BrandPalette.dark
      : BrandPalette.light;
}

const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

/// Gaya serif untuk angka dan judul besar.
///
/// Kontras antara serif untuk angka dan sans untuk teks biasa adalah hal
/// tunggal yang paling membuat tampilan terasa dirancang, bukan dirakit.
class AppSerif {
  const AppSerif._();

  static const String family = 'Fraunces';

  static const hero = TextStyle(
    fontFamily: family,
    fontSize: 44,
    height: 1.02,
    fontWeight: FontWeight.w500,
    letterSpacing: -1.4,
    fontFeatures: _tabular,
  );

  static const title = TextStyle(
    fontFamily: family,
    fontSize: 26,
    height: 1.1,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.5,
  );

  static const number = TextStyle(
    fontFamily: family,
    fontSize: 22,
    height: 1.1,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.3,
    fontFeatures: _tabular,
  );
}