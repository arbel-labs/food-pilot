import 'package:flutter_test/flutter_test.dart';

import 'package:foodpilot/domain/hpp.dart';
import 'package:foodpilot/domain/models.dart';

Ingredient bahan(double qty, IngredientUnit unit, int unitPrice) => Ingredient(
  id: 'x',
  name: 'bahan',
  qty: qty,
  unit: unit,
  unitPrice: unitPrice,
);

void main() {
  group('hpp', () {
    test('tanpa bahan hasilnya nol', () {
      expect(hpp(const <Ingredient>[]), 0);
    });

    test('menjumlahkan qty dikali harga satuan', () {
      final value = hpp(<Ingredient>[
        bahan(150, IngredientUnit.gram, 14),
        bahan(1, IngredientUnit.pcs, 8500),
      ]);
      expect(value, 2100 + 8500);
    });

    test('qty desimal dibulatkan ke rupiah terdekat', () {
      expect(hpp(<Ingredient>[bahan(0.5, IngredientUnit.pcs, 2201)]), 1101);
    });
  });

  group('margin', () {
    test('harga jual nol tidak membagi dengan nol', () {
      expect(margin(sellPrice: 0, cost: 5000), isNull);
    });

    test('margin positif', () {
      expect(margin(sellPrice: 20000, cost: 15000), closeTo(0.25, 0.0001));
    });

    test('margin negatif saat modal lebih besar dari harga', () {
      expect(margin(sellPrice: 6000, cost: 6500), lessThan(0));
    });
  });

  group('marginBand', () {
    test('null dianggap rugi', () => expect(marginBand(null), MarginBand.loss));
    test('negatif rugi', () => expect(marginBand(-0.1), MarginBand.loss));
    test('di bawah 20 persen tipis', () {
      expect(marginBand(0.19), MarginBand.thin);
    });
    test('20 persen ke atas sehat', () {
      expect(marginBand(0.2), MarginBand.healthy);
    });
  });

  test('profitPerUnit', () {
    expect(profitPerUnit(sellPrice: 18000, cost: 11900), 6100);
  });
}
