import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:foodpilot/data/providers.dart';
import 'package:foodpilot/domain/ai_summary.dart';
import 'package:foodpilot/domain/classify.dart';
import 'package:foodpilot/domain/models.dart';
import 'package:foodpilot/domain/weekly_pattern.dart';
import 'package:foodpilot/shared/dates.dart';

/// Jendela analisis menu: 30 hari terakhir.
const int analysisWindowDays = 30;

/// Jendela pola mingguan: 8 minggu terakhir.
const int patternWindowDays = 56;

class AnalisisData {
  const AnalisisData({
    required this.business,
    required this.sales,
    required this.products,
    required this.analysis,
    required this.pattern,
    required this.from,
    required this.to,
    required this.monthlyCost,
    required this.costsFilled,
  });

  final Business business;

  /// Penjualan di dalam jendela analisis.
  final List<DaySale> sales;
  final Map<String, Product> products;
  final MenuAnalysis analysis;
  final WeeklyPattern pattern;
  final DateTime from;
  final DateTime to;
  final int monthlyCost;
  final bool costsFilled;

  int get daysWithData => sales.where((sale) => sale.lines.isNotEmpty).length;
}

final analisisProvider = FutureProvider<AnalisisData?>((ref) async {
  final business = await ref.watch(businessProvider.future);
  if (business == null) return null;

  final sales = await ref.watch(recentSalesProvider.future);
  final products = await ref.watch(productsProvider.future);
  final costs = await ref.watch(costsProvider(periodKey(today())).future);

  final to = today();
  final from = to.subtract(const Duration(days: analysisWindowDays - 1));
  final patternFrom = to.subtract(const Duration(days: patternWindowDays - 1));

  final window = sales.where((sale) => !sale.date.isBefore(from)).toList();
  final patternWindow = sales
      .where((sale) => !sale.date.isBefore(patternFrom))
      .toList();

  var monthlyCost = 0;
  for (final cost in costs) {
    monthlyCost += cost.amount;
  }

  return AnalisisData(
    business: business,
    sales: window,
    products: <String, Product>{
      for (final product in products) product.id: product,
    },
    analysis: classifyMenus(window),
    pattern: weeklyPattern(patternWindow),
    from: from,
    to: to,
    monthlyCost: monthlyCost,
    costsFilled: costs.isNotEmpty,
  );
});

/// Ringkasan angka yang dikirim ke konsultan AI.
final aiSummaryProvider = FutureProvider<AiSummary?>((ref) async {
  final data = await ref.watch(analisisProvider.future);
  if (data == null) return null;
  return buildAiSummary(
    business: data.business,
    sales: data.sales,
    from: data.from,
    to: data.to,
    monthlyCost: data.monthlyCost,
    costsFilled: data.costsFilled,
    analysis: data.analysis,
    pattern: data.pattern,
  );
});
