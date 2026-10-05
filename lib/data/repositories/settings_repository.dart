
import 'package:foodpilot/data/database.dart';

/// Pengaturan kecil milik perangkat, disimpan sebagai pasangan kunci-nilai.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  Stream<Map<String, String>> watchAll() =>
      _db.select(_db.appSettings).watch().map(_toMap);

  Future<Map<String, String>> getAll() async =>
      _toMap(await _db.select(_db.appSettings).get());

  Future<String?> get(String key) async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((t) => t.settingKey.equals(key))).getSingleOrNull();
    return row?.settingValue;
  }

  Future<void> set(String key, String value) async {
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(settingKey: key, settingValue: value),
        );
  }

  Future<void> remove(String key) async {
    await (_db.delete(
      _db.appSettings,
    )..where((t) => t.settingKey.equals(key))).go();
  }

  Map<String, String> _toMap(List<SettingRow> rows) => <String, String>{
    for (final row in rows) row.settingKey: row.settingValue,
  };
}
