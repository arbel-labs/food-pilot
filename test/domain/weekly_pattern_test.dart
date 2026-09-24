import 'package:flutter_test/flutter_test.dart';

import 'package:foodpilot/domain/models.dart';
import 'package:foodpilot/domain/weekly_pattern.dart';

DaySale hari(DateTime date, int revenue) => DaySale(
  id: date.toString(),
  date: date,
  lines: <SaleLine>[
    SaleLine(
      productId: 'p',
      productName: 'Menu',
      qty: 1,
      unitPrice: revenue,
      unitCost: 0,
    ),
  ],
  updatedAt: date,
);

void main() {
  test('data kurang dari tujuh hari belum cukup', () {
    final pattern = weeklyPattern(<DaySale>[
      hari(DateTime(2026, 9, 14), 100000),
    ]);
    expect(pattern.hasEnoughData, isFalse);
    expect(pattern.conclusion, contains('7 hari'));
  });

  test('rata-rata per hari dihitung dari jumlah kemunculan', () {
    // Dua hari Senin: 100.000 dan 200.000, sisanya satu kali 100.000.
    final sales = <DaySale>[
      hari(DateTime(2026, 9, 7), 100000),
      hari(DateTime(2026, 9, 14), 200000),
      for (var day = 8; day <= 13; day++) hari(DateTime(2026, 9, day), 100000),
    ];
    final pattern = weeklyPattern(sales);
    final senin = pattern.days.firstWhere((day) => day.weekday == 1);
    expect(senin.samples, 2);
    expect(senin.average, 150000);
    expect(pattern.hasEnoughData, isTrue);
  });

  test('hari yang jauh di atas rata-rata disebut paling ramai', () {
    final sales = <DaySale>[
      for (var day = 7; day <= 12; day++) hari(DateTime(2026, 9, day), 100000),
      hari(DateTime(2026, 9, 13), 400000),
    ];
    final pattern = weeklyPattern(sales);
    expect(pattern.conclusion, contains('Minggu'));
    expect(pattern.conclusion, contains('Paling ramai'));
  });

  test('penjualan merata menghasilkan kesimpulan netral', () {
    final sales = <DaySale>[
      for (var day = 7; day <= 13; day++) hari(DateTime(2026, 9, day), 100000),
    ];
    expect(weeklyPattern(sales).conclusion, contains('merata'));
  });
}
