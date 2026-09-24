import 'package:flutter/material.dart';

import 'package:foodpilot/app/theme/app_colors.dart';
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
      decoration: ShapeDecoration(color: background, shape: const StadiumBorder()),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: foreground),
      ),
    );
  }
}

/// Badge margin di daftar menu: rugi merah, tipis amber, sehat hijau.
class MarginBadge extends StatelessWidget {
  const MarginBadge({required this.margin, super.key});

  final double? margin;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final value = margin;
    final band = marginBand(value);

    final (Color background, Color foreground, String label) = switch (band) {
      MarginBand.loss => (
        colors.danger,
        colors.onDanger,
        value == null ? 'Harga belum diisi' : 'Rugi ${formatPercent(value)}',
      ),
      MarginBand.thin => (
        colors.warning,
        colors.onWarning,
        'Tipis ${formatPercent(value!)}',
      ),
      MarginBand.healthy => (
        colors.success,
        colors.onSuccess,
        'Margin ${formatPercent(value!)}',
      ),
    };

    return StatusChip(
      label: label,
      background: background,
      foreground: foreground,
    );
  }
}
