import 'dart:math';

import 'package:drift/drift.dart';

import 'package:foodpilot/core/ids.dart';
import 'package:foodpilot/data/database.dart';
import 'package:foodpilot/domain/models.dart';
import 'package:foodpilot/shared/dates.dart';

/// Data contoh 30 hari untuk demo dan pengujian (PRD bagian 7).
///
/// Angkanya sengaja dibuat supaya ketiga kelompok menu muncul: ada yang
/// untung besar, ada yang laku tapi tipis, dan ada yang rugi.
class SeedService {
  SeedService(this._db);

  final AppDatabase _db;

  static const int days = 30;

  Future<void> run() async {
    final now = nowMillis();
    final businessId = newId();
    final random = Random(7);

    await _db.transaction(() async {
      await _db
          .into(_db.businesses)
          .insert(
            BusinessesCompanion.insert(
              id: businessId,
              name: 'Warung Bu Sri',
              type: BusinessType.kuliner.name,
              openTime: const Value('07:00'),
              closeTime: const Value('17:00'),
              operatingDays: const Value(30),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final products = <_SeedProduct>[
        _SeedProduct('Nasi ayam goreng', 18000, 26, <_SeedIngredient>[
          _SeedIngredient('Beras', 150, IngredientUnit.gram, 14),
          _SeedIngredient('Ayam potong', 1, IngredientUnit.pcs, 8500),
          _SeedIngredient('Minyak goreng', 30, IngredientUnit.ml, 20),
          _SeedIngredient('Bumbu', 1, IngredientUnit.sdm, 400),
        ]),
        _SeedProduct('Nasi goreng', 20000, 18, <_SeedIngredient>[
          _SeedIngredient('Beras', 200, IngredientUnit.gram, 14),
          _SeedIngredient('Telur', 1, IngredientUnit.pcs, 2200),
          _SeedIngredient('Minyak goreng', 20, IngredientUnit.ml, 20),
          _SeedIngredient('Bumbu', 2, IngredientUnit.sdm, 400),
          _SeedIngredient('Kerupuk', 1, IngredientUnit.pcs, 500),
        ]),
        _SeedProduct('Mie goreng', 17000, 12, <_SeedIngredient>[
          _SeedIngredient('Mie telur', 1, IngredientUnit.pcs, 3500),
          _SeedIngredient('Telur', 1, IngredientUnit.pcs, 2200),
          _SeedIngredient('Sayur', 50, IngredientUnit.gram, 15),
          _SeedIngredient('Minyak goreng', 20, IngredientUnit.ml, 20),
        ]),
        _SeedProduct('Soto ayam', 15000, 10, <_SeedIngredient>[
          _SeedIngredient('Ayam suwir', 80, IngredientUnit.gram, 60),
          _SeedIngredient('Beras', 150, IngredientUnit.gram, 14),
          _SeedIngredient('Soun', 30, IngredientUnit.gram, 40),
          _SeedIngredient('Bumbu kuah', 1, IngredientUnit.pcs, 2500),
        ]),
        _SeedProduct('Pecel lele', 16000, 9, <_SeedIngredient>[
          _SeedIngredient('Lele', 1, IngredientUnit.pcs, 9000),
          _SeedIngredient('Beras', 150, IngredientUnit.gram, 14),
          _SeedIngredient('Minyak goreng', 40, IngredientUnit.ml, 20),
          _SeedIngredient('Lalapan', 1, IngredientUnit.pcs, 1500),
        ]),
        _SeedProduct('Tempe goreng', 3000, 22, <_SeedIngredient>[
          _SeedIngredient('Tempe', 1, IngredientUnit.pcs, 1500),
          _SeedIngredient('Tepung', 20, IngredientUnit.gram, 12),
          _SeedIngredient('Minyak goreng', 15, IngredientUnit.ml, 20),
        ]),
        _SeedProduct('Es teh manis', 5000, 30, <_SeedIngredient>[
          _SeedIngredient('Teh celup', 1, IngredientUnit.pcs, 300),
          _SeedIngredient('Gula', 20, IngredientUnit.gram, 17),
          _SeedIngredient('Es batu', 1, IngredientUnit.pcs, 500),
        ]),
        _SeedProduct('Es jeruk', 7000, 11, <_SeedIngredient>[
          _SeedIngredient('Jeruk peras', 2, IngredientUnit.pcs, 1500),
          _SeedIngredient('Gula', 20, IngredientUnit.gram, 17),
          _SeedIngredient('Es batu', 1, IngredientUnit.pcs, 500),
        ]),
        // Sengaja rugi: biar kelompok "menguras tanpa hasil" terlihat.
        _SeedProduct('Kopi susu gula aren', 6000, 4, <_SeedIngredient>[
          _SeedIngredient('Kopi bubuk', 15, IngredientUnit.gram, 220),
          _SeedIngredient('Susu', 80, IngredientUnit.ml, 25),
          _SeedIngredient('Gula aren', 1, IngredientUnit.sdm, 800),
        ]),
      ];

      var sortOrder = 0;
      for (final product in products) {
        product.id = newId();
        await _db
            .into(_db.products)
            .insert(
              ProductsCompanion.insert(
                id: product.id,
                businessId: businessId,
                name: product.name,
                sellPrice: product.price,
                sortOrder: Value(sortOrder++),
                createdAt: now,
                updatedAt: now,
              ),
            );
        await _db.batch((batch) {
          batch.insertAll(_db.ingredients, <IngredientsCompanion>[
            for (final ingredient in product.ingredients)
              IngredientsCompanion.insert(
                id: newId(),
                productId: product.id,
                name: ingredient.name,
                qty: ingredient.qty,
                unit: ingredient.unit.name,
                unitPrice: ingredient.unitPrice,
                createdAt: now,
              ),
          ]);
        });
      }

      final start = today().subtract(const Duration(days: days - 1));
      for (var dayIndex = 0; dayIndex < days; dayIndex++) {
        final date = start.add(Duration(days: dayIndex));
        final saleId = newId();
        await _db
            .into(_db.sales)
            .insert(
              SalesCompanion.insert(
                id: saleId,
                businessId: businessId,
                saleDate: dateKey(date),
                createdAt: now,
                updatedAt: now,
              ),
            );

        await _db.batch((batch) {
          batch.insertAll(_db.saleItems, <SaleItemsCompanion>[
            for (final product in products)
              if (_qtyFor(product, date, random) case final qty when qty > 0)
                SaleItemsCompanion.insert(
                  id: newId(),
                  saleId: saleId,
                  productId: product.id,
                  qty: qty,
                  unitPrice: product.price,
                  unitCost: product.cost,
                ),
          ]);
        });
      }

      final period = periodKey(today());
      final costs = <String, int>{
        'Sewa tempat': 1500000,
        'Gaji karyawan': 1800000,
        'Listrik': 350000,
        'Gas': 400000,
        'Air': 100000,
      };
      await _db.batch((batch) {
        batch.insertAll(_db.operatingCosts, <OperatingCostsCompanion>[
          for (final entry in costs.entries)
            OperatingCostsCompanion.insert(
              id: newId(),
              businessId: businessId,
              period: period,
              name: entry.key,
              amount: entry.value,
              createdAt: now,
            ),
        ]);
      });
    });
  }

  /// Akhir pekan lebih ramai, Senin lebih sepi, ditambah sedikit acak.
  int _qtyFor(_SeedProduct product, DateTime date, Random random) {
    final weekdayFactor = switch (date.weekday) {
      DateTime.saturday => 1.4,
      DateTime.sunday => 1.35,
      DateTime.friday => 1.15,
      DateTime.monday => 0.8,
      _ => 1.0,
    };
    final noise = 0.8 + random.nextDouble() * 0.4;
    return (product.baseQty * weekdayFactor * noise).round();
  }
}

class _SeedIngredient {
  const _SeedIngredient(this.name, this.qty, this.unit, this.unitPrice);

  final String name;
  final double qty;
  final IngredientUnit unit;
  final int unitPrice;
}

class _SeedProduct {
  _SeedProduct(this.name, this.price, this.baseQty, this.ingredients);

  final String name;
  final int price;
  final int baseQty;
  final List<_SeedIngredient> ingredients;
  String id = '';

  int get cost {
    var total = 0.0;
    for (final ingredient in ingredients) {
      total += ingredient.qty * ingredient.unitPrice;
    }
    return total.round();
  }
}
