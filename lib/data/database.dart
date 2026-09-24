import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

// Tabel mengikuti CONTEXT.md bagian 3. Nama data class ditulis eksplisit
// dengan akhiran "Row" supaya tidak tertukar dengan model di lib/domain/.
// File database.g.dart dibuat oleh: dart run build_runner build

@DataClassName('BusinessRow')
class Businesses extends Table {
  @override
  String get tableName => 'business';

  TextColumn get id => text()();
  TextColumn get name => text()();

  /// 'kuliner' | 'fashion' | 'jasa'
  TextColumn get type => text()();

  /// 'HH:MM'
  TextColumn get openTime => text().nullable()();
  TextColumn get closeTime => text().nullable()();
  IntColumn get operatingDays => integer().withDefault(const Constant(30))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ProductRow')
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(Businesses, #id)();
  TextColumn get name => text()();
  TextColumn get category => text().nullable()();

  /// Rupiah.
  IntColumn get sellPrice => integer()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('IngredientRow')
class Ingredients extends Table {
  TextColumn get id => text()();
  TextColumn get productId =>
      text().references(Products, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();

  /// Jumlah bahan, boleh desimal.
  RealColumn get qty => real()();

  /// 'gram' | 'ml' | 'pcs' | 'sdm'
  TextColumn get unit => text()();

  /// Rupiah per satuan.
  IntColumn get unitPrice => integer()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SaleRow')
class Sales extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(Businesses, #id)();

  /// 'YYYY-MM-DD'
  TextColumn get saleDate => text()();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {businessId, saleDate},
  ];
}

@DataClassName('SaleItemRow')
class SaleItems extends Table {
  TextColumn get id => text()();
  TextColumn get saleId =>
      text().references(Sales, #id, onDelete: KeyAction.cascade)();
  TextColumn get productId => text().references(Products, #id)();
  IntColumn get qty => integer()();

  /// Snapshot harga jual saat transaksi.
  IntColumn get unitPrice => integer()();

  /// Snapshot modal per porsi (HPP) saat transaksi.
  IntColumn get unitCost => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('OperatingCostRow')
class OperatingCosts extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(Businesses, #id)();

  /// 'YYYY-MM'
  TextColumn get period => text()();
  TextColumn get name => text()();
  IntColumn get amount => integer()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {businessId, period, name},
  ];
}

@DataClassName('AiAnalysisRow')
class AiAnalyses extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text().references(Businesses, #id)();
  TextColumn get periodStart => text()();
  TextColumn get periodEnd => text()();

  /// JSON ringkasan yang dikirim ke AI.
  TextColumn get inputSummary => text()();

  /// JSON balasan AI.
  TextColumn get result => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Pengaturan kecil milik perangkat: pengingat, mode demo, draf catat.
@DataClassName('SettingRow')
class AppSettings extends Table {
  @override
  String get tableName => 'app_settings';

  TextColumn get settingKey => text()();
  TextColumn get settingValue => text()();

  @override
  Set<Column<Object>> get primaryKey => {settingKey};
}

@DriftDatabase(
  tables: [
    Businesses,
    Products,
    Ingredients,
    Sales,
    SaleItems,
    OperatingCosts,
    AiAnalyses,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Tanpa argumen membuka file `foodpilot.sqlite` di folder aplikasi. Test
  /// memberikan database di memori.
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'foodpilot'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      // SQLite mematikan foreign key secara bawaan. Tanpa ini ON DELETE
      // CASCADE di ingredients dan sale_items tidak berjalan.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
