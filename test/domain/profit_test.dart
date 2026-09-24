import 'package:flutter_test/flutter_test.dart';

import 'package:foodpilot/domain/models.dart';
import 'package:foodpilot/domain/profit.dart';

SaleLine baris({int qty = 1, int price = 10000, int cost = 6000}) => SaleLine(
  productId: 'p',
  productName: 'Menu',
  qty: qty,
  unitPrice: price,
  unitCost: cost,
);

void main() {
  test('grossProfit satu baris', () {
    expect(grossProfit(baris(qty: 3, price: 18000, cost: 11900)), 18300);
  });

  test('dailyRevenue dan dailyGrossProfit menjumlahkan semua baris', () {
    final lines = <SaleLine>[
      baris(qty: 2, price: 18000, cost: 12000),
      baris(qty: 5, price: 5000, cost: 1100),
    ];
    expect(dailyRevenue(lines), 36000 + 25000);
    expect(dailyGrossProfit(lines), 12000 + 19500);
    expect(totalQty(lines), 7);
  });

  group('dailyFixedCost', () {
    test('dibagi hari operasional lalu dibulatkan', () {
      expect(dailyFixedCost(monthlyCost: 4150000, operatingDays: 30), 138333);
    });

    test('hari operasional nol tidak membagi dengan nol', () {
      expect(dailyFixedCost(monthlyCost: 300000, operatingDays: 0), 300000);
    });
  });

  group('dailyNetProfit', () {
    test('laba kotor dikurangi biaya tetap', () {
      final net = dailyNetProfit(
        lines: <SaleLine>[baris(qty: 10, price: 18000, cost: 12000)],
        dailyFixedCost: 40000,
        costsFilled: true,
      );
      expect(net.value, 20000);
      expect(net.isEstimate, isFalse);
    });

    test('ditandai estimasi kalau biaya belum diisi', () {
      final net = dailyNetProfit(
        lines: <SaleLine>[baris()],
        dailyFixedCost: 0,
        costsFilled: false,
      );
      expect(net.isEstimate, isTrue);
    });
  });
}
