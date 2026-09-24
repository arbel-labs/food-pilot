/// Ringkasan angka yang dikirim ke konsultan AI.
///
/// Semua angka dihitung di sini. AI hanya menarasikan, tidak menghitung
/// (CONTEXT.md bagian 2 dan 6).
library;

import 'package:foodpilot/domain/breakeven.dart';
import 'package:foodpilot/domain/classify.dart';
import 'package:foodpilot/domain/models.dart';
import 'package:foodpilot/domain/profit.dart';
import 'package:foodpilot/domain/weekly_pattern.dart';
import 'package:foodpilot/shared/dates.dart';

class AiSummary {
  const AiSummary({
    required this.periodStart,
    required this.periodEnd,
    required this.daysWithData,
    required this.payload,
  });

  final String periodStart;
  final String periodEnd;
  final int daysWithData;
  final Map<String, Object?> payload;
}

AiSummary buildAiSummary({
  required Business business,
  required List<DaySale> sales,
  required DateTime from,
  required DateTime to,
  required int monthlyCost,
  required bool costsFilled,
  required MenuAnalysis analysis,
  required WeeklyPattern pattern,
}) {
  final lines = <SaleLine>[for (final sale in sales) ...sale.lines];
  final days = sales.where((sale) => sale.lines.isNotEmpty).length;
  final fixed = dailyFixedCost(
    monthlyCost: monthlyCost,
    operatingDays: business.operatingDays,
  );
  final revenue = dailyRevenue(lines);
  final gross = dailyGrossProfit(lines);
  final averageRevenue = days == 0 ? 0 : (revenue / days).round();
  final averageGross = days == 0 ? 0 : (gross / days).round();

  final breakEvenInfo = switch (breakEven(dailyFixedCost: fixed, lines: lines)) {
    BreakEvenUnits(:final units) => <String, Object?>{
      'status': 'bisa_dihitung',
      'porsi_per_hari': units,
    },
    BreakEvenNoData() => <String, Object?>{'status': 'belum_ada_data'},
    BreakEvenNoProfit() => <String, Object?>{'status': 'rata_rata_rugi'},
  };

  final menus = switch (analysis) {
    MenuAnalysisReady(:final items) => <Object?>[
      for (final item in items.take(15))
        <String, Object?>{
          'nama': item.name,
          'kelompok': item.menuClass.label,
          'terjual': item.qty,
          'pendapatan': item.revenue,
          'laba_kotor': item.grossProfit,
          'margin_persen': (item.margin * 100).round(),
          'kontribusi_persen': (item.contribution * 100).round(),
        },
    ],
    MenuAnalysisNotEnoughData() => const <Object?>[],
  };

  final payload = <String, Object?>{
    'mata_uang': 'IDR (rupiah, bilangan bulat)',
    'usaha': <String, Object?>{
      'nama': business.name,
      'jenis': business.type.label,
      'satuan_terjual': business.type.unitWord,
      'hari_operasional_per_bulan': business.operatingDays,
    },
    'periode': <String, Object?>{
      'mulai': dateKey(from),
      'akhir': dateKey(to),
      'hari_berisi_penjualan': days,
    },
    'total_periode': <String, Object?>{
      'pendapatan': revenue,
      'laba_kotor': gross,
      'terjual': totalQty(lines),
    },
    'rata_rata_harian': <String, Object?>{
      'pendapatan': averageRevenue,
      'laba_kotor': averageGross,
      'biaya_tetap': fixed,
      'laba_bersih': averageGross - fixed,
    },
    'biaya_operasional': <String, Object?>{
      'per_bulan': monthlyCost,
      'sudah_diisi': costsFilled,
    },
    'balik_modal': breakEvenInfo,
    'menu': menus,
    'pola_mingguan': <String, Object?>{
      'kesimpulan': pattern.conclusion,
      'rata_rata_pendapatan_per_hari': <String, Object?>{
        for (final day in pattern.days)
          if (day.samples > 0) dayName(day.weekday): day.average,
      },
    },
  };

  return AiSummary(
    periodStart: dateKey(from),
    periodEnd: dateKey(to),
    daysWithData: days,
    payload: payload,
  );
}
