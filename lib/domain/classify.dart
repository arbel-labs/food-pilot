/// Klasifikasi menu, CONTEXT.md bagian 4.
library;

import 'package:foodpilot/domain/models.dart';
import 'package:foodpilot/domain/profit.dart';

/// Minimal hari berisi penjualan sebelum klasifikasi boleh ditampilkan.
const int minimumAnalysisDays = 7;

enum MenuClass {
  mainContributor('Penyumbang laba utama'),
  popularThin('Laku tapi tipis'),
  drain('Menguras tanpa hasil');

  const MenuClass(this.label);

  final String label;
}

class MenuPerformance {
  const MenuPerformance({
    required this.productId,
    required this.name,
    required this.qty,
    required this.revenue,
    required this.grossProfit,
    required this.margin,
    required this.contribution,
    required this.menuClass,
  });

  final String productId;
  final String name;
  final int qty;
  final int revenue;
  final int grossProfit;

  /// Margin nyata dari penjualan: laba kotor ÷ pendapatan.
  final double margin;

  /// Laba kotor menu ini ÷ laba kotor semua menu.
  final double contribution;
  final MenuClass menuClass;
}

sealed class MenuAnalysis {
  const MenuAnalysis();
}

final class MenuAnalysisNotEnoughData extends MenuAnalysis {
  const MenuAnalysisNotEnoughData(this.days);

  /// Hari berisi penjualan yang sudah ada.
  final int days;
}

final class MenuAnalysisReady extends MenuAnalysis {
  const MenuAnalysisReady(this.items);

  /// Diurutkan dari laba kotor terbesar.
  final List<MenuPerformance> items;

  List<MenuPerformance> ofClass(MenuClass menuClass) =>
      items.where((item) => item.menuClass == menuClass).toList();
}

/// Mengelompokkan menu dari penjualan dalam periode tertentu.
///
/// Aturan dievaluasi berurutan:
/// 1. margin < 0 → menguras tanpa hasil
/// 2. kontribusi ≥ rata-rata kontribusi → penyumbang laba utama
/// 3. qty ≥ median qty dan margin < rata-rata margin → laku tapi tipis
/// 4. selain itu → menguras tanpa hasil
MenuAnalysis classifyMenus(List<DaySale> sales) {
  final days = sales.where((sale) => sale.lines.isNotEmpty).length;
  if (days < minimumAnalysisDays) return MenuAnalysisNotEnoughData(days);

  final totals = <String, _Totals>{};
  for (final sale in sales) {
    for (final line in sale.lines) {
      final total = totals.putIfAbsent(
        line.productId,
        () => _Totals(line.productName),
      );
      total.qty += line.qty;
      total.revenue += line.unitPrice * line.qty;
      total.gross += grossProfit(line);
    }
  }
  if (totals.isEmpty) return MenuAnalysisNotEnoughData(days);

  var allGross = 0;
  for (final total in totals.values) {
    allGross += total.gross;
  }

  final contributions = <String, double>{
    for (final entry in totals.entries)
      entry.key: allGross <= 0 ? 0 : entry.value.gross / allGross,
  };
  final margins = <String, double>{
    for (final entry in totals.entries)
      entry.key: entry.value.revenue == 0
          ? 0
          : entry.value.gross / entry.value.revenue,
  };

  final averageContribution = _mean(contributions.values);
  final averageMargin = _mean(margins.values);
  final medianQty = _median(totals.values.map((total) => total.qty).toList());

  final items = <MenuPerformance>[
    for (final entry in totals.entries)
      MenuPerformance(
        productId: entry.key,
        name: entry.value.name,
        qty: entry.value.qty,
        revenue: entry.value.revenue,
        grossProfit: entry.value.gross,
        margin: margins[entry.key]!,
        contribution: contributions[entry.key]!,
        menuClass: _classOf(
          margin: margins[entry.key]!,
          contribution: contributions[entry.key]!,
          qty: entry.value.qty,
          averageContribution: averageContribution,
          averageMargin: averageMargin,
          medianQty: medianQty,
        ),
      ),
  ]..sort((a, b) => b.grossProfit.compareTo(a.grossProfit));

  return MenuAnalysisReady(items);
}

MenuClass _classOf({
  required double margin,
  required double contribution,
  required int qty,
  required double averageContribution,
  required double averageMargin,
  required double medianQty,
}) {
  if (margin < 0) return MenuClass.drain;
  if (contribution >= averageContribution) return MenuClass.mainContributor;
  if (qty >= medianQty && margin < averageMargin) return MenuClass.popularThin;
  return MenuClass.drain;
}

double _mean(Iterable<double> values) {
  if (values.isEmpty) return 0;
  var sum = 0.0;
  for (final value in values) {
    sum += value;
  }
  return sum / values.length;
}

double _median(List<int> values) {
  if (values.isEmpty) return 0;
  final sorted = [...values]..sort();
  final middle = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[middle].toDouble();
  return (sorted[middle - 1] + sorted[middle]) / 2;
}

class _Totals {
  _Totals(this.name);

  final String name;
  int qty = 0;
  int revenue = 0;
  int gross = 0;
}
