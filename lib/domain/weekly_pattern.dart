/// Pola penjualan mingguan dan kalimat kesimpulannya (PRD F-07).
///
/// Kesimpulan dibuat dari aturan sederhana, bukan AI.
library;

import 'package:foodpilot/domain/models.dart';
import 'package:foodpilot/domain/profit.dart';

class WeekdayRevenue {
  const WeekdayRevenue({
    required this.weekday,
    required this.average,
    required this.samples,
  });

  /// 1 = Senin, 7 = Minggu.
  final int weekday;

  /// Rata-rata pendapatan pada hari itu.
  final int average;

  /// Berapa kali hari itu tercatat dalam data.
  final int samples;
}

class WeeklyPattern {
  const WeeklyPattern({
    required this.days,
    required this.conclusion,
    required this.hasEnoughData,
  });

  final List<WeekdayRevenue> days;
  final String conclusion;
  final bool hasEnoughData;
}

/// Selisih minimal dari rata-rata supaya sebuah hari disebut menonjol.
const double _notableGap = 0.3;

WeeklyPattern weeklyPattern(List<DaySale> sales) {
  final totals = List<int>.filled(7, 0);
  final counts = List<int>.filled(7, 0);
  for (final sale in sales) {
    if (sale.lines.isEmpty) continue;
    final index = sale.date.weekday - 1;
    totals[index] += dailyRevenue(sale.lines);
    counts[index]++;
  }

  final days = <WeekdayRevenue>[
    for (var i = 0; i < 7; i++)
      WeekdayRevenue(
        weekday: i + 1,
        average: counts[i] == 0 ? 0 : (totals[i] / counts[i]).round(),
        samples: counts[i],
      ),
  ];

  final recorded = counts.fold(0, (sum, count) => sum + count);
  if (recorded < 7) {
    return WeeklyPattern(
      days: days,
      conclusion: 'Butuh minimal 7 hari data untuk melihat pola mingguan.',
      hasEnoughData: false,
    );
  }

  final withData = days.where((day) => day.samples > 0).toList();
  final overall =
      withData.fold(0, (sum, day) => sum + day.average) / withData.length;
  if (overall <= 0) {
    return WeeklyPattern(
      days: days,
      conclusion: 'Belum ada pendapatan yang tercatat.',
      hasEnoughData: false,
    );
  }

  final best = withData.reduce((a, b) => b.average > a.average ? b : a);
  final worst = withData.reduce((a, b) => b.average < a.average ? b : a);
  final bestGap = best.average / overall - 1;
  final worstGap = 1 - worst.average / overall;

  final String conclusion;
  if (bestGap >= _notableGap && bestGap >= worstGap) {
    conclusion =
        'Paling ramai hari ${dayName(best.weekday)}, sekitar '
        '${(bestGap * 100).round()}% di atas rata-rata. Siapkan bahan lebih '
        'banyak sehari sebelumnya.';
  } else if (worstGap >= _notableGap) {
    conclusion =
        'Paling sepi hari ${dayName(worst.weekday)}, sekitar '
        '${(worstGap * 100).round()}% di bawah rata-rata. Hari itu cocok '
        'untuk mencoba promo.';
  } else {
    conclusion = 'Penjualan cukup merata sepanjang minggu.';
  }

  return WeeklyPattern(days: days, conclusion: conclusion, hasEnoughData: true);
}
