import 'package:flutter_test/flutter_test.dart';

import 'package:foodpilot/domain/classify.dart';
import 'package:foodpilot/domain/models.dart';

DaySale hari(int day, List<SaleLine> lines) => DaySale(
  id: 'sale-$day',
  date: DateTime(2026, 9, day),
  lines: lines,
  updatedAt: DateTime(2026, 9, day),
);

SaleLine baris(
  String id,
  String name, {
  required int qty,
  required int price,
  required int cost,
}) => SaleLine(
  productId: id,
  productName: name,
  qty: qty,
  unitPrice: price,
  unitCost: cost,
);

List<DaySale> tujuhHari(List<SaleLine> lines) =>
    <DaySale>[for (var day = 1; day <= 7; day++) hari(day, lines)];

void main() {
  test('kurang dari tujuh hari data belum bisa dianalisis', () {
    final result = classifyMenus(<DaySale>[
      for (var day = 1; day <= 6; day++)
        hari(day, <SaleLine>[baris('a', 'A', qty: 1, price: 10000, cost: 5000)]),
    ]);
    expect(result, isA<MenuAnalysisNotEnoughData>());
    expect((result as MenuAnalysisNotEnoughData).days, 6);
  });

  test('hari tanpa penjualan tidak dihitung sebagai hari data', () {
    final result = classifyMenus(<DaySale>[
      for (var day = 1; day <= 8; day++)
        hari(day, day.isEven ? const <SaleLine>[] : <SaleLine>[
          baris('a', 'A', qty: 1, price: 10000, cost: 5000),
        ]),
    ]);
    expect(result, isA<MenuAnalysisNotEnoughData>());
  });

  test('margin negatif selalu masuk menguras tanpa hasil', () {
    final result =
        classifyMenus(
              tujuhHari(<SaleLine>[
                baris('a', 'Untung', qty: 10, price: 20000, cost: 8000),
                baris('b', 'Rugi', qty: 30, price: 6000, cost: 6500),
              ]),
            )
            as MenuAnalysisReady;

    final rugi = result.items.firstWhere((item) => item.productId == 'b');
    expect(rugi.menuClass, MenuClass.drain);
    expect(rugi.margin, lessThan(0));
  });

  test('kontribusi di atas rata-rata jadi penyumbang laba utama', () {
    final result =
        classifyMenus(
              tujuhHari(<SaleLine>[
                baris('a', 'Andalan', qty: 20, price: 20000, cost: 8000),
                baris('b', 'Kecil', qty: 2, price: 5000, cost: 3000),
              ]),
            )
            as MenuAnalysisReady;

    expect(
      result.items.firstWhere((item) => item.productId == 'a').menuClass,
      MenuClass.mainContributor,
    );
    expect(result.ofClass(MenuClass.mainContributor), hasLength(1));
  });

  test('laku banyak tapi margin di bawah rata-rata jadi laku tapi tipis', () {
    final result =
        classifyMenus(
              tujuhHari(<SaleLine>[
                baris('a', 'Andalan', qty: 10, price: 20000, cost: 5000),
                baris('b', 'Laku tipis', qty: 40, price: 6000, cost: 5400),
                baris('c', 'Jarang', qty: 1, price: 9000, cost: 4000),
              ]),
            )
            as MenuAnalysisReady;

    expect(
      result.items.firstWhere((item) => item.productId == 'b').menuClass,
      MenuClass.popularThin,
    );
  });

  test('item diurutkan dari laba kotor terbesar', () {
    final result =
        classifyMenus(
              tujuhHari(<SaleLine>[
                baris('kecil', 'Kecil', qty: 1, price: 5000, cost: 3000),
                baris('besar', 'Besar', qty: 10, price: 20000, cost: 8000),
              ]),
            )
            as MenuAnalysisReady;

    expect(result.items.first.productId, 'besar');
  });
}
