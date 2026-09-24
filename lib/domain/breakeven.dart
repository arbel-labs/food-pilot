/// Titik balik modal harian, CONTEXT.md bagian 4.
library;

import 'package:foodpilot/domain/models.dart';
import 'package:foodpilot/domain/profit.dart';

/// Hasil perhitungan balik modal. Kasus tepi punya tipe sendiri supaya UI
/// bisa menjelaskannya, bukan menampilkan angka tak hingga atau negatif.
sealed class BreakEven {
  const BreakEven();
}

/// Perlu menjual [units] porsi per hari untuk menutup biaya tetap harian.
final class BreakEvenUnits extends BreakEven {
  const BreakEvenUnits(this.units);

  final int units;
}

/// Belum ada penjualan, jadi rata-rata laba per porsi belum ada.
final class BreakEvenNoData extends BreakEven {
  const BreakEvenNoData();
}

/// Rata-rata laba per porsi nol atau negatif: berapa pun yang terjual, biaya
/// tetap tidak akan tertutup.
final class BreakEvenNoProfit extends BreakEven {
  const BreakEvenNoProfit();
}

/// Σ laba kotor ÷ Σ porsi. `null` kalau belum ada porsi terjual.
double? averageProfitPerUnit(Iterable<SaleLine> lines) {
  final qty = totalQty(lines);
  if (qty == 0) return null;
  return dailyGrossProfit(lines) / qty;
}

/// `ceil(biaya tetap harian ÷ rata-rata laba per porsi)`.
BreakEven breakEven({
  required int dailyFixedCost,
  required Iterable<SaleLine> lines,
}) {
  final average = averageProfitPerUnit(lines);
  if (average == null) return const BreakEvenNoData();
  if (average <= 0) return const BreakEvenNoProfit();
  if (dailyFixedCost <= 0) return const BreakEvenUnits(0);
  return BreakEvenUnits((dailyFixedCost / average).ceil());
}
