import 'package:flutter_test/flutter_test.dart';

import 'package:foodpilot/domain/breakeven.dart';
import 'package:foodpilot/domain/models.dart';

SaleLine baris({required int qty, required int price, required int cost}) =>
    SaleLine(
      productId: 'p',
      productName: 'Menu',
      qty: qty,
      unitPrice: price,
      unitCost: cost,
    );

void main() {
  test('belum ada penjualan', () {
    expect(
      breakEven(dailyFixedCost: 100000, lines: const <SaleLine>[]),
      isA<BreakEvenNoData>(),
    );
  });

  test('semua menu rugi', () {
    final result = breakEven(
      dailyFixedCost: 100000,
      lines: <SaleLine>[baris(qty: 10, price: 6000, cost: 6500)],
    );
    expect(result, isA<BreakEvenNoProfit>());
  });

  test('rata-rata laba per porsi nol juga dianggap tidak bisa balik modal', () {
    final result = breakEven(
      dailyFixedCost: 50000,
      lines: <SaleLine>[baris(qty: 4, price: 10000, cost: 10000)],
    );
    expect(result, isA<BreakEvenNoProfit>());
  });

  test('biaya tetap nol berarti sudah balik modal', () {
    final result = breakEven(
      dailyFixedCost: 0,
      lines: <SaleLine>[baris(qty: 4, price: 10000, cost: 6000)],
    );
    expect(result, isA<BreakEvenUnits>());
    expect((result as BreakEvenUnits).units, 0);
  });

  test('dibulatkan ke atas', () {
    // Rata-rata laba 4.000 per porsi, biaya tetap 138.000 → 34,5 → 35.
    final result = breakEven(
      dailyFixedCost: 138000,
      lines: <SaleLine>[baris(qty: 10, price: 10000, cost: 6000)],
    );
    expect((result as BreakEvenUnits).units, 35);
  });

  test('averageProfitPerUnit null saat belum ada porsi', () {
    expect(averageProfitPerUnit(const <SaleLine>[]), isNull);
  });
}
