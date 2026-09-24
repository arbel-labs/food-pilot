import 'package:drift/drift.dart';

import 'package:foodpilot/core/ids.dart';
import 'package:foodpilot/data/database.dart';
import 'package:foodpilot/domain/hpp.dart';
import 'package:foodpilot/domain/models.dart';
import 'package:foodpilot/shared/dates.dart';

/// Keadaan penjualan satu hari sebelum penyimpanan terakhir, untuk tombol
/// urungkan di snackbar.
class UndoToken {
  const UndoToken({required this.date, required this.previousLines});

  final DateTime date;

  /// `null` berarti hari itu belum punya catatan sama sekali sebelumnya.
  final List<SaleLine>? previousLines;
}

class SalesRepository {
  SalesRepository(this._db);

  final AppDatabase _db;

  Stream<List<DaySale>> watchSalesSince(DateTime from) =>
      _joined(from: dateKey(from)).watch().map(_group);

  Future<List<DaySale>> salesSince(DateTime from) async =>
      _group(await _joined(from: dateKey(from)).get());

  Future<DaySale?> getSaleForDate(DateTime date) async {
    final key = dateKey(date);
    final grouped = _group(await _joined(exact: key).get());
    if (grouped.isNotEmpty) return grouped.first;

    // Hari itu bisa saja tersimpan tanpa satu pun porsi.
    final sale = await (_db.select(
      _db.sales,
    )..where((t) => t.saleDate.equals(key))).getSingleOrNull();
    if (sale == null) return null;
    return DaySale(
      id: sale.id,
      date: parseDateKey(sale.saleDate),
      lines: const <SaleLine>[],
      updatedAt: DateTime.fromMillisecondsSinceEpoch(sale.updatedAt),
    );
  }

  /// Menyimpan penjualan satu hari. Mencatat ulang tanggal yang sama menimpa
  /// baris yang sama, tidak menduplikasi (PRD F-03).
  ///
  /// Harga jual dan modal per porsi ikut disimpan sebagai snapshot, supaya
  /// laporan bulan lalu tetap memakai angka bulan lalu.
  Future<UndoToken> saveSale({
    required DateTime date,
    required Map<String, int> quantities,
    required List<Product> products,
  }) async {
    final key = dateKey(date);
    final businessId = await _businessId();
    final previous = await getSaleForDate(date);
    final now = nowMillis();
    final byId = <String, Product>{
      for (final product in products) product.id: product,
    };

    await _db.transaction(() async {
      final existing = await (_db.select(
        _db.sales,
      )..where((t) => t.saleDate.equals(key))).getSingleOrNull();
      final saleId = existing?.id ?? newId();

      if (existing == null) {
        await _db
            .into(_db.sales)
            .insert(
              SalesCompanion.insert(
                id: saleId,
                businessId: businessId,
                saleDate: key,
                createdAt: now,
                updatedAt: now,
              ),
            );
      } else {
        await (_db.update(
          _db.sales,
        )..where((t) => t.id.equals(saleId))).write(
          SalesCompanion(updatedAt: Value(now)),
        );
        await (_db.delete(
          _db.saleItems,
        )..where((t) => t.saleId.equals(saleId))).go();
      }

      await _db.batch((batch) {
        batch.insertAll(_db.saleItems, <SaleItemsCompanion>[
          for (final entry in quantities.entries)
            if (entry.value > 0 && byId.containsKey(entry.key))
              SaleItemsCompanion.insert(
                id: newId(),
                saleId: saleId,
                productId: entry.key,
                qty: entry.value,
                unitPrice: byId[entry.key]!.sellPrice,
                unitCost: hpp(byId[entry.key]!.ingredients),
              ),
        ]);
      });
    });

    return UndoToken(date: date, previousLines: previous?.lines);
  }

  Future<void> undo(UndoToken token) async {
    final key = dateKey(token.date);
    final previous = token.previousLines;

    await _db.transaction(() async {
      final existing = await (_db.select(
        _db.sales,
      )..where((t) => t.saleDate.equals(key))).getSingleOrNull();
      if (existing == null) return;

      if (previous == null) {
        await (_db.delete(
          _db.sales,
        )..where((t) => t.id.equals(existing.id))).go();
        return;
      }

      await (_db.delete(
        _db.saleItems,
      )..where((t) => t.saleId.equals(existing.id))).go();
      await _db.batch((batch) {
        batch.insertAll(_db.saleItems, <SaleItemsCompanion>[
          for (final line in previous)
            SaleItemsCompanion.insert(
              id: newId(),
              saleId: existing.id,
              productId: line.productId,
              qty: line.qty,
              unitPrice: line.unitPrice,
              unitCost: line.unitCost,
            ),
        ]);
      });
      await (_db.update(
        _db.sales,
      )..where((t) => t.id.equals(existing.id))).write(
        SalesCompanion(updatedAt: Value(nowMillis())),
      );
    });
  }

  JoinedSelectStatement<HasResultSet, dynamic> _joined({
    String? from,
    String? exact,
  }) {
    final query = _db.select(_db.saleItems).join(<Join<HasResultSet, dynamic>>[
      innerJoin(_db.sales, _db.sales.id.equalsExp(_db.saleItems.saleId)),
      innerJoin(
        _db.products,
        _db.products.id.equalsExp(_db.saleItems.productId),
      ),
    ]);
    if (exact != null) {
      query.where(_db.sales.saleDate.equals(exact));
    } else if (from != null) {
      query.where(_db.sales.saleDate.isBiggerOrEqualValue(from));
    }
    return query;
  }

  List<DaySale> _group(List<TypedResult> rows) {
    final sales = <String, SaleRow>{};
    final lines = <String, List<SaleLine>>{};

    for (final row in rows) {
      final sale = row.readTable(_db.sales);
      final item = row.readTable(_db.saleItems);
      final product = row.readTable(_db.products);
      sales[sale.id] = sale;
      lines
          .putIfAbsent(sale.id, () => <SaleLine>[])
          .add(
            SaleLine(
              productId: item.productId,
              productName: product.name,
              qty: item.qty,
              unitPrice: item.unitPrice,
              unitCost: item.unitCost,
            ),
          );
    }

    return <DaySale>[
      for (final sale in sales.values)
        DaySale(
          id: sale.id,
          date: parseDateKey(sale.saleDate),
          lines: lines[sale.id] ?? const <SaleLine>[],
          updatedAt: DateTime.fromMillisecondsSinceEpoch(sale.updatedAt),
        ),
    ]..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<String> _businessId() async {
    final row = await (_db.select(_db.businesses)..limit(1)).getSingleOrNull();
    if (row == null) {
      throw StateError('Data usaha belum ada, penjualan tidak bisa disimpan.');
    }
    return row.id;
  }
}
