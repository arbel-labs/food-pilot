import 'package:drift/drift.dart';

import 'package:foodpilot/core/ids.dart';
import 'package:foodpilot/data/database.dart';
import 'package:foodpilot/domain/models.dart';

class BusinessRepository {
  BusinessRepository(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$BusinessesTable, BusinessRow> get _first =>
      _db.select(_db.businesses)..limit(1);

  Stream<Business?> watchBusiness() =>
      _first.watchSingleOrNull().map((row) => row == null ? null : _toModel(row));

  Future<Business?> getBusiness() async {
    final row = await _first.getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  Future<bool> hasBusiness() async => await getBusiness() != null;

  /// Membuat usaha baru, atau mengubah usaha yang sudah ada. Aplikasi ini
  /// hanya menyimpan satu usaha.
  Future<Business> save({
    required String name,
    required BusinessType type,
    String? openTime,
    String? closeTime,
    int operatingDays = 30,
  }) async {
    final now = nowMillis();
    final existing = await getBusiness();
    if (existing == null) {
      final id = newId();
      await _db
          .into(_db.businesses)
          .insert(
            BusinessesCompanion.insert(
              id: id,
              name: name,
              type: type.name,
              openTime: Value(openTime),
              closeTime: Value(closeTime),
              operatingDays: Value(operatingDays),
              createdAt: now,
              updatedAt: now,
            ),
          );
    } else {
      await (_db.update(
        _db.businesses,
      )..where((t) => t.id.equals(existing.id))).write(
        BusinessesCompanion(
          name: Value(name),
          type: Value(type.name),
          openTime: Value(openTime),
          closeTime: Value(closeTime),
          operatingDays: Value(operatingDays),
          updatedAt: Value(now),
        ),
      );
    }
    return (await getBusiness())!;
  }

  static Business _toModel(BusinessRow row) => Business(
    id: row.id,
    name: row.name,
    type: BusinessType.fromId(row.type),
    openTime: row.openTime,
    closeTime: row.closeTime,
    operatingDays: row.operatingDays,
  );
}
