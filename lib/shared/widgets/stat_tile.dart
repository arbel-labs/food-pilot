import 'package:flutter/material.dart';

import 'package:foodpilot/app/theme/app_colors.dart';
import 'package:foodpilot/app/theme/tokens.dart';

/// Kotak statistik: satu angka dan satu label (CONTEXT.md bagian 7).
class StatTile extends StatelessWidget {
  const StatTile({
    required this.value,
    required this.label,
    this.valueColor,
    super.key,
  });

  final String value;
  final String label;

  /// Warna status hanya kalau angkanya bermakna finansial.
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpace.s12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Angka yang terlalu panjang mengecil, tidak terpotong.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: textTheme.titleLarge?.copyWith(
                color: valueColor ?? colors.text,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.s4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
