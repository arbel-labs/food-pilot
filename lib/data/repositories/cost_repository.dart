import 'package:drift/drift.dart';

import 'package:foodpilot/core/ids.dart';
import 'package:foodpilot/data/database.dart';
import 'package:foodpilot/domain/models.dart';
import 'package:foodpilot/shared/dates.dart';

class DuplicateCostException implements Exception {
  const DuplicateCostException(this.name);

  final String name;

  String get message => 'Biaya bernama "$name" sudah ada di bulan ini.';

  @override
  String toString() => message;
}

class CostRepository {
  CostRepository(this._db);

  final AppDatabase _db;

  Stream<List<CostItem>> watchCosts(String period) =>
      _query(period).watch().map(_toModels);

  Future<List<CostItem>> costsFor(String period) async =>
      _toModels(await _query(period).get());

  Future<void> saveCost({
    String? id,
    required String period,
    required String name,
    required int amount,
  }) async {
    final clash = await (_db.select(_db.operatingCosts)
          ..where((t) => t.period.equals(period) & t.name.equals(name)))
        .getSingleOrNull();
    if (clash != null && clash.id != id) throw DuplicateCostException(name);

    if (id == null) {
      final businessId = await _businessId();
      await _db
          .into(_db.operatingCosts)
          .insert(
            OperatingCostsCompanion.insert(
              id: newId(),
              businessId: businessId,
              period: period,
              name: name,
              amount: amount,
              createdAt: nowMillis(),
            ),
          );
    } else {
      await (_db.update(
        _db.operatingCosts,
      )..where((t) => t.id.equals(id))).write(
        OperatingCostsCompanion(name: Value(name), amount: Value(amount)),
      );
    }
  }

  Future<void> deleteCost(String id) async {
    await (_db.delete(_db.operatingCosts)..where((t) => t.id.equals(id))).go();
  }

  /// Menyalin biaya bulan sebelumnya yang belum ada di [period].
  /// Mengembalikan jumlah baris yang tersalin.
  Future<int> copyFromPreviousPeriod(String period) async {
    final previous = await costsFor(previousPeriod(period));
    if (previous.isEmpty) return 0;

    final current = await costsFor(period);
    final existingNames = current.map((cost) => cost.name).toSet();
    final toCopy = previous
        .where((cost) => !existingNames.contains(cost.name))
        .toList();
    if (toCopy.isEmpty) return 0;

    final businessId = await _businessId();
    final now = nowMillis();
    await _db.batch((batch) {
      batch.insertAll(_db.operatingCosts, <OperatingCostsCompanion>[
        for (final cost in toCopy)
          OperatingCostsCompanion.insert(
            id: newId(),
            businessId: businessId,
            period: period,
            name: cost.name,
            amount: cost.amount,
            createdAt: now,
          ),
      ]);
    });
    return toCopy.length;
  }

  SimpleSelectStatement<$OperatingCostsTable, OperatingCostRow> _query(
    String period,
  ) {
    return _db.select(_db.operatingCosts)
      ..where((t) => t.period.equals(period))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
  }

  List<CostItem> _toModels(List<OperatingCostRow> rows) => <CostItem>[
    for (final row in rows)
      CostItem(
        id: row.id,
        period: row.period,
        name: row.name,
        amount: row.amount,
      ),
  ];

  Future<String> _businessId() async {
    final row = await (_db.select(_db.businesses)..limit(1)).getSingleOrNull();
    if (row == null) {
      throw StateError('Data usaha belum ada, biaya tidak bisa disimpan.');
    }
    return row.id;
  }
}
