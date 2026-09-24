/// Rekap bulanan untuk laporan PDF (PRD F-12).
library;

import 'package:foodpilot/domain/models.dart';
import 'package:foodpilot/domain/profit.dart';

class MenuTotal {
  const MenuTotal({
    required this.name,
    required this.qty,
    required this.revenue,
    required this.grossProfit,
  });

  final String name;
  final int qty;
  final int revenue;
  final int grossProfit;
}

class DayTotal {
  const DayTotal({
    required this.date,
    required this.qty,
    required this.revenue,
    required this.grossProfit,
  });

  final DateTime date;
  final int qty;
  final int revenue;
  final int grossProfit;
}

class MonthlyReport {
  const MonthlyReport({
    required this.period,
    required this.revenue,
    required this.grossProfit,
    required this.operatingCost,
    required this.costsFilled,
    required this.qty,
    required this.days,
    required this.menus,
    required this.costs,
  });

  final String period;
  final int revenue;
  final int grossProfit;
  final int operatingCost;
  final bool costsFilled;
  final int qty;
  final List<DayTotal> days;
  final List<MenuTotal> menus;
  final List<CostItem> costs;

  /// Laba bersih bulan ini: laba kotor − seluruh biaya operasional bulan itu.
  int get netProfit => grossProfit - operatingCost;
}

/// [sales] boleh berisi hari di luar [period]; yang dipakai hanya hari di
/// dalam periode itu.
MonthlyReport buildMonthlyReport({
  required String period,
  required List<DaySale> sales,
  required List<CostItem> costs,
}) {
  final inPeriod = sales.where((sale) {
    final month = sale.date.month.toString().padLeft(2, '0');
    return '${sale.date.year}-$month' == period;
  }).toList()..sort((a, b) => a.date.compareTo(b.date));

  final lines = <SaleLine>[for (final sale in inPeriod) ...sale.lines];
  final menus = <String, MenuTotal>{};
  for (final line in lines) {
    final current = menus[line.productId];
    menus[line.productId] = MenuTotal(
      name: line.productName,
      qty: (current?.qty ?? 0) + line.qty,
      revenue: (current?.revenue ?? 0) + line.unitPrice * line.qty,
      grossProfit: (current?.grossProfit ?? 0) + grossProfit(line),
    );
  }

  var operatingCost = 0;
  for (final cost in costs) {
    operatingCost += cost.amount;
  }

  return MonthlyReport(
    period: period,
    revenue: dailyRevenue(lines),
    grossProfit: dailyGrossProfit(lines),
    operatingCost: operatingCost,
    costsFilled: costs.isNotEmpty,
    qty: totalQty(lines),
    days: <DayTotal>[
      for (final sale in inPeriod)
        DayTotal(
          date: sale.date,
          qty: totalQty(sale.lines),
          revenue: dailyRevenue(sale.lines),
          grossProfit: dailyGrossProfit(sale.lines),
        ),
    ],
    menus: menus.values.toList()
      ..sort((a, b) => b.grossProfit.compareTo(a.grossProfit)),
    costs: costs,
  );
}
