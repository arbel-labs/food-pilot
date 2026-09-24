import 'package:flutter/material.dart';

import 'package:foodpilot/app/theme/app_colors.dart';
import 'package:foodpilot/app/theme/tokens.dart';
import 'package:foodpilot/domain/weekly_pattern.dart';
import 'package:foodpilot/shared/format.dart';

/// Grafik batang rata-rata pendapatan per hari (PRD F-07).
///
/// Digambar dengan widget biasa, tanpa paket grafik, supaya ringan di HP
/// kelas bawah dan warnanya ikut sistem desain.
class WeeklyChart extends StatelessWidget {
  const WeeklyChart({required this.pattern, super.key});

  final WeeklyPattern pattern;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final maxAverage = pattern.days.fold<int>(
      0,
      (max, day) => day.average > max ? day.average : max,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 132,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              for (final day in pattern.days)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          day.average == 0
                              ? '—'
                              : formatRupiahCompact(
                                  day.average,
                                ).replaceAll('Rp ', ''),
                          maxLines: 1,
                          style: textTheme.bodySmall?.copyWith(fontSize: 10),
                        ),
                        const SizedBox(height: AppSpace.s4),
                        Container(
                          height: maxAverage == 0
                              ? 4
                              : 4 + 80 * day.average / maxAverage,
                          decoration: BoxDecoration(
                            color: day.samples == 0
                                ? colors.border
                                : colors.ink,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpace.s4),
                        Text(
                          dayShort(day.weekday),
                          style: textTheme.bodySmall?.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s12),
        Text(pattern.conclusion, style: textTheme.bodyMedium),
      ],
    );
  }
}
