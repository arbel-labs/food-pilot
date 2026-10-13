import 'package:flutter/material.dart';

import 'package:foodpilot/app/theme/app_colors.dart';
import 'package:foodpilot/app/theme/brand.dart';
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
    final brand = context.brand;
    final textTheme = Theme.of(context).textTheme;

    final maxAverage = pattern.days.fold<int>(
      0,
      (max, day) => day.average > max ? day.average : max,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              for (final day in pattern.days)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _Bar(
                      day: day,
                      // Hari tertinggi diberi warna merek penuh. Sisanya
                      // versi lembut, supaya mata langsung menemukan
                      // puncaknya tanpa perlu membaca semua angka.
                      isPeak: maxAverage > 0 && day.average == maxAverage,
                      ratio: maxAverage == 0 ? 0 : day.average / maxAverage,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s16),
        Container(height: 0.5, color: colors.border),
        const SizedBox(height: AppSpace.s12),
        Text(
          pattern.conclusion,
          style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
        ),
        if (maxAverage == 0) ...<Widget>[
          const SizedBox(height: AppSpace.s4),
          Text(
            'Belum ada penjualan tercatat minggu ini.',
            style: textTheme.bodySmall,
          ),
        ],
        // Keterangan warna ditaruh di bawah supaya tidak menambah elemen di
        // area grafiknya sendiri.
        if (maxAverage > 0) ...<Widget>[
          const SizedBox(height: AppSpace.s8),
          Row(
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: ShapeDecoration(
                  color: brand.brand,
                  shape: const CircleBorder(),
                ),
              ),
              const SizedBox(width: AppSpace.s8),
              Text('Hari paling ramai', style: textTheme.bodySmall),
            ],
          ),
        ],
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.day,
    required this.isPeak,
    required this.ratio,
  });

  final WeekdayRevenue day;
  final bool isPeak;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;
    final textTheme = Theme.of(context).textTheme;

    final Color barColor = day.samples == 0
        ? colors.border
        : isPeak
        ? brand.brand
        : brand.brandTint;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Text(
          day.average == 0
              ? '—'
              : formatRupiahCompact(day.average).replaceAll('Rp ', ''),
          maxLines: 1,
          style: textTheme.bodySmall?.copyWith(
            fontSize: 10,
            color: isPeak ? colors.text : colors.textMuted,
            fontWeight: isPeak ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        const SizedBox(height: AppSpace.s4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          height: 6 + 78 * ratio,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(height: AppSpace.s8),
        Text(
          dayShort(day.weekday),
          style: textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: isPeak ? colors.text : colors.textMuted,
            fontWeight: isPeak ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}