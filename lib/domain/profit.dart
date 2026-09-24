/// Rumus laba, CONTEXT.md bagian 4.
library;

import 'package:foodpilot/domain/models.dart';

/// Laba kotor satu baris: (harga jual − modal) × jumlah.
int grossProfit(SaleLine line) => (line.unitPrice - line.unitCost) * line.qty;

/// Pendapatan: Σ(harga jual × jumlah).
int dailyRevenue(Iterable<SaleLine> lines) {
  var total = 0;
  for (final line in lines) {
    total += line.unitPrice * line.qty;
  }
  return total;
}

/// Laba kotor: Σ laba kotor tiap baris.
int dailyGrossProfit(Iterable<SaleLine> lines) {
  var total = 0;
  for (final line in lines) {
    total += grossProfit(line);
  }
  return total;
}

/// Jumlah porsi terjual.
int totalQty(Iterable<SaleLine> lines) {
  var total = 0;
  for (final line in lines) {
    total += line.qty;
  }
  return total;
}

/// Biaya tetap harian: total biaya operasional bulanan ÷ hari operasional,
/// dibulatkan ke rupiah terdekat.
int dailyFixedCost({required int monthlyCost, required int operatingDays}) {
  if (operatingDays <= 0) return monthlyCost;
  return (monthlyCost / operatingDays).round();
}

class NetProfit {
  const NetProfit({required this.value, required this.isEstimate});

  final int value;

  /// Biaya operasional bulan ini belum diisi, jadi laba bersih masih estimasi.
  final bool isEstimate;
}

/// Laba bersih harian: laba kotor − biaya tetap harian.
NetProfit dailyNetProfit({
  required Iterable<SaleLine> lines,
  required int dailyFixedCost,
  required bool costsFilled,
}) {
  return NetProfit(
    value: dailyGrossProfit(lines) - dailyFixedCost,
    isEstimate: !costsFilled,
  );
}
