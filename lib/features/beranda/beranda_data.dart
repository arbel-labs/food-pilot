import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:foodpilot/data/providers.dart';
import 'package:foodpilot/domain/breakeven.dart';
import 'package:foodpilot/domain/models.dart';
import 'package:foodpilot/domain/profit.dart';
import 'package:foodpilot/shared/dates.dart';

class TopMenu {
  const TopMenu({required this.name, required this.qty});

  final String name;
  final int qty;
}

class BerandaData {
  const BerandaData({
    required this.business,
    required this.date,
    required this.todayLines,
    required this.net,
    required this.revenue,
    required this.qty,
    required this.breakEvenResult,
    required this.dailyFixed,
    required this.costsFilled,
    required this.hasTodaySale,
    required this.topMenus,
    required this.showCostBanner,
  });

  final Business business;
  final DateTime date;
  final List<SaleLine> todayLines;
  final NetProfit net;
  final int revenue;
  final int qty;
  final BreakEven breakEvenResult;
  final int dailyFixed;
  final bool costsFilled;
  final bool hasTodaySale;
  final List<TopMenu> topMenus;

  /// Tawaran mengisi biaya operasional muncul setelah tiga hari data
  /// (PRD F-01), bukan saat onboarding.
  final bool showCostBanner;
}

/// Hari yang dipakai untuk rata-rata laba per porsi dan menu terlaris.
const int berandaWindowDays = 30;

final berandaProvider = FutureProvider<BerandaData?>((ref) async {
  final business = await ref.watch(businessProvider.future);
  if (business == null) return null;

  final sales = await ref.watch(recentSalesProvider.future);
  final date = today();
  final costs = await ref.watch(costsProvider(periodKey(date)).future);

  var monthlyCost = 0;
  for (final cost in costs) {
    monthlyCost += cost.amount;
  }
  final fixed = dailyFixedCost(
    monthlyCost: monthlyCost,
    operatingDays: business.operatingDays,
  );

  final todayKey = dateKey(date);
  DaySale? todaySale;
  for (final sale in sales) {
    if (dateKey(sale.date) == todayKey) todaySale = sale;
  }

  final from = date.subtract(const Duration(days: berandaWindowDays - 1));
  final window = sales.where((sale) => !sale.date.isBefore(from)).toList();
  final windowLines = <SaleLine>[for (final sale in window) ...sale.lines];

  final qtyByProduct = <String, int>{};
  final nameByProduct = <String, String>{};
  for (final line in windowLines) {
    qtyByProduct[line.productId] = (qtyByProduct[line.productId] ?? 0) + line.qty;
    nameByProduct[line.productId] = line.productName;
  }
  final top = qtyByProduct.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final todayLines = todaySale?.lines ?? const <SaleLine>[];

  return BerandaData(
    business: business,
    date: date,
    todayLines: todayLines,
    net: dailyNetProfit(
      lines: todayLines,
      dailyFixedCost: fixed,
      costsFilled: costs.isNotEmpty,
    ),
    revenue: dailyRevenue(todayLines),
    qty: totalQty(todayLines),
    // Rata-rata laba per porsi diambil dari 30 hari terakhir supaya titik
    // balik modal tidak melompat-lompat mengikuti satu hari saja.
    breakEvenResult: breakEven(dailyFixedCost: fixed, lines: windowLines),
    dailyFixed: fixed,
    costsFilled: costs.isNotEmpty,
    hasTodaySale: todaySale != null,
    topMenus: <TopMenu>[
      for (final entry in top.take(3))
        TopMenu(name: nameByProduct[entry.key] ?? '', qty: entry.value),
    ],
    showCostBanner:
        costs.isEmpty &&
        window.where((sale) => sale.lines.isNotEmpty).length >= 3,
  );
});
