import 'package:flutter/material.dart';

import 'package:foodpilot/app/theme/app_colors.dart';
import 'package:foodpilot/app/theme/brand.dart';
import 'package:foodpilot/app/theme/tokens.dart';
import 'package:foodpilot/domain/hpp.dart';
import 'package:foodpilot/shared/format.dart';

/// Chip kecil berwarna status. Warna hijau, amber, dan merah hanya untuk
/// makna finansial (CONTEXT.md bagian 7).
class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    required this.background,
    required this.foreground,
    super.key,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s8,
        vertical: AppSpace.s4,
      ),
      decoration: ShapeDecoration(
        color: background,
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Warna untuk satu pita margin: latar lembut, teks berwarna penuh.
///
/// Dipakai badge sekaligus kotak ikon di baris menu supaya statusnya
/// terbaca dua kali tanpa menambah elemen baru.
({Color background, Color foreground}) marginBandColors(
  BuildContext context,
  MarginBand band,
) {
  final colors = context.colors;
  final brand = context.brand;

  return switch (band) {
    MarginBand.loss => (
      background: brand.dangerTint,
      foreground: colors.danger,
    ),
    MarginBand.thin => (
      background: brand.warningTint,
      foreground: colors.warning,
    ),
    MarginBand.healthy => (
      background: brand.successTint,
      foreground: colors.success,
    ),
  };
}

/// Badge margin di daftar menu: rugi merah, tipis amber, sehat hijau.
///
/// Latarnya versi lembut, bukan warna penuh. Dengan banyak kartu dalam satu
/// layar, badge berwarna penuh ikut bersaing dengan warna merek dan membuat
/// daftarnya terasa ramai.
class MarginBadge extends StatelessWidget {
  const MarginBadge({required this.margin, super.key});

  final double? margin;

  @override
  Widget build(BuildContext context) {
    final value = margin;
    final band = marginBand(value);
    final tone = marginBandColors(context, band);

    final String label = switch (band) {
      MarginBand.loss =>
        value == null ? 'Harga belum diisi' : 'Rugi ${formatPercent(value)}',
      MarginBand.thin => 'Tipis ${formatPercent(value!)}',
      MarginBand.healthy => 'Margin ${formatPercent(value!)}',
    };

    return StatusChip(
      label: label,
      background: tone.background,
      foreground: tone.foreground,
    );
  }
}