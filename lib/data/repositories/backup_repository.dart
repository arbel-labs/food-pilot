import 'package:drift/drift.dart';

import 'package:foodpilot/data/database.dart';

/// Ekspor dan impor seluruh isi database sebagai JSON.
///
/// Dipakai fitur cadangan (PRD F-14) dan tombol hapus semua data.
class BackupRepository {
  BackupRepository(this._db);

  final AppDatabase _db;

  static const int formatVersion = 1;

  Future<Map<String, Object?>> export() async {
    return <String, Object?>{
      'version': formatVersion,
      'dibuat': DateTime.now().toIso8601String(),
      'business': _json(await _db.select(_db.businesses).get()),
      'products': _json(await _db.select(_db.products).get()),
      'ingredients': _json(await _db.select(_db.ingredients).get()),
      'sales': _json(await _db.select(_db.sales).get()),
      'sale_items': _json(await _db.select(_db.saleItems).get()),
      'operating_costs': _json(await _db.select(_db.operatingCosts).get()),
      'ai_analyses': _json(await _db.select(_db.aiAnalyses).get()),
    };
  }

  /// Mengganti seluruh isi database dengan isi cadangan.
  Future<void> import(Map<String, dynamic> payload) async {
    await _db.transaction(() async {
      await _clear();
      await _db.batch((batch) {
        batch.insertAll(
          _db.businesses,
          _rows(payload['business'], BusinessRow.fromJson),
        );
        batch.insertAll(
          _db.products,
          _rows(payload['products'], ProductRow.fromJson),
        );
        batch.insertAll(
          _db.ingredients,
          _rows(payload['ingredients'], IngredientRow.fromJson),
        );
        batch.insertAll(_db.sales, _rows(payload['sales'], SaleRow.fromJson));
        batch.insertAll(
          _db.saleItems,
          _rows(payload['sale_items'], SaleItemRow.fromJson),
        );
        batch.insertAll(
          _db.operatingCosts,
          _rows(payload['operating_costs'], OperatingCostRow.fromJson),
        );
        batch.insertAll(
          _db.aiAnalyses,
          _rows(payload['ai_analyses'], AiAnalysisRow.fromJson),
        );
      });
    });
  }

  Future<void> deleteAll() => _db.transaction(_clear);

  Future<void> _clear() async {
    // Urutan penting: anak dulu, induk belakangan, karena foreign key aktif.
    await _db.delete(_db.saleItems).go();
    await _db.delete(_db.sales).go();
    await _db.delete(_db.ingredients).go();
    await _db.delete(_db.aiAnalyses).go();
    await _db.delete(_db.operatingCosts).go();
    await _db.delete(_db.products).go();
    await _db.delete(_db.businesses).go();
  }

  List<Map<String, dynamic>> _json(List<DataClass> rows) =>
      <Map<String, dynamic>>[for (final row in rows) row.toJson()];

  List<T> _rows<T>(Object? value, T Function(Map<String, dynamic>) fromJson) {
    if (value is! List) return <T>[];
    return <T>[
      for (final item in value)
        if (item is Map<String, dynamic>) fromJson(item),
    ];
  }
}
