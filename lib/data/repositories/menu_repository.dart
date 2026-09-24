import 'package:drift/drift.dart';

import 'package:foodpilot/core/ids.dart';
import 'package:foodpilot/data/database.dart';
import 'package:foodpilot/domain/models.dart';

/// Isian satu baris bahan dari form, sebelum punya id.
class IngredientInput {
  const IngredientInput({
    required this.name,
    required this.qty,
    required this.unit,
    required this.unitPrice,
  });

  final String name;
  final double qty;
  final IngredientUnit unit;
  final int unitPrice;
}

class MenuRepository {
  MenuRepository(this._db);

  final AppDatabase _db;

  /// Semua menu, aktif dan nonaktif, lengkap dengan bahannya.
  ///
  /// Menyimpan menu selalu mengubah baris products (updated_at), jadi stream
  /// ini ikut terpicu walau yang berubah hanya bahannya.
  Stream<List<Product>> watchProducts() {
    final query = _db.select(_db.products)
      ..orderBy([
        (t) => OrderingTerm.asc(t.sortOrder),
        (t) => OrderingTerm.asc(t.name),
      ]);
    return query.watch().asyncMap(_withIngredients);
  }

  Future<Product?> getProduct(String id) async {
    final row = await (_db.select(
      _db.products,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final products = await _withIngredients([row]);
    return products.single;
  }

  Future<String> saveProduct({
    String? id,
    required String businessId,
    required String name,
    required int sellPrice,
    required List<IngredientInput> ingredients,
    bool isActive = true,
  }) async {
    final now = nowMillis();
    final productId = id ?? newId();

    await _db.transaction(() async {
      if (id == null) {
        final count = (await _db.select(_db.products).get()).length;
        await _db
            .into(_db.products)
            .insert(
              ProductsCompanion.insert(
                id: productId,
                businessId: businessId,
                name: name,
                sellPrice: sellPrice,
                isActive: Value(isActive),
                sortOrder: Value(count),
                createdAt: now,
                updatedAt: now,
              ),
            );
      } else {
        await (_db.update(
          _db.products,
        )..where((t) => t.id.equals(productId))).write(
          ProductsCompanion(
            name: Value(name),
            sellPrice: Value(sellPrice),
            isActive: Value(isActive),
            updatedAt: Value(now),
          ),
        );
      }

      // Bahan disimpan ulang seluruhnya: lebih sederhana daripada mencocokkan
      // baris satu per satu, dan riwayat penjualan tidak terpengaruh karena
      // modal per porsi sudah di-snapshot di sale_items.
      await (_db.delete(
        _db.ingredients,
      )..where((t) => t.productId.equals(productId))).go();
      await _db.batch((batch) {
        batch.insertAll(_db.ingredients, <IngredientsCompanion>[
          for (final item in ingredients)
            IngredientsCompanion.insert(
              id: newId(),
              productId: productId,
              name: item.name,
              qty: item.qty,
              unit: item.unit.name,
              unitPrice: item.unitPrice,
              createdAt: now,
            ),
        ]);
      });
    });

    return productId;
  }

  /// Menonaktifkan menu tanpa menghapus riwayat penjualannya.
  Future<void> setActive(String id, {required bool active}) async {
    await (_db.update(_db.products)..where((t) => t.id.equals(id))).write(
      ProductsCompanion(isActive: Value(active), updatedAt: Value(nowMillis())),
    );
  }

  Future<List<Product>> _withIngredients(List<ProductRow> rows) async {
    if (rows.isEmpty) return const <Product>[];
    final ids = rows.map((row) => row.id).toList();
    final ingredientRows = await (_db.select(
      _db.ingredients,
    )..where((t) => t.productId.isIn(ids))).get();

    final byProduct = <String, List<Ingredient>>{};
    for (final row in ingredientRows) {
      byProduct
          .putIfAbsent(row.productId, () => <Ingredient>[])
          .add(
            Ingredient(
              id: row.id,
              name: row.name,
              qty: row.qty,
              unit: IngredientUnit.fromId(row.unit),
              unitPrice: row.unitPrice,
            ),
          );
    }

    return <Product>[
      for (final row in rows)
        Product(
          id: row.id,
          name: row.name,
          category: row.category,
          sellPrice: row.sellPrice,
          isActive: row.isActive,
          sortOrder: row.sortOrder,
          ingredients: byProduct[row.id] ?? const <Ingredient>[],
        ),
    ];
  }
}
