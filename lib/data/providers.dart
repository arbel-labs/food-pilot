import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:foodpilot/data/database.dart';
import 'package:foodpilot/data/repositories/analysis_repository.dart';
import 'package:foodpilot/data/repositories/backup_repository.dart';
import 'package:foodpilot/data/repositories/business_repository.dart';
import 'package:foodpilot/data/repositories/cost_repository.dart';
import 'package:foodpilot/data/repositories/menu_repository.dart';
import 'package:foodpilot/data/repositories/sales_repository.dart';
import 'package:foodpilot/data/repositories/settings_repository.dart';
import 'package:foodpilot/data/seed.dart';
import 'package:foodpilot/domain/ai_result.dart';
import 'package:foodpilot/domain/models.dart';
import 'package:foodpilot/shared/dates.dart';

/// Diisi di main.dart lewat ProviderScope(overrides: ...), supaya database
/// bisa diganti versi memori saat test.
final Provider<AppDatabase> databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider harus di-override di main.dart');
});

/// Rute awal: onboarding kalau tabel business masih kosong.
final Provider<String> initialLocationProvider = Provider<String>(
  (ref) => '/beranda',
);

final businessRepositoryProvider = Provider<BusinessRepository>(
  (ref) => BusinessRepository(ref.watch(databaseProvider)),
);
final menuRepositoryProvider = Provider<MenuRepository>(
  (ref) => MenuRepository(ref.watch(databaseProvider)),
);
final salesRepositoryProvider = Provider<SalesRepository>(
  (ref) => SalesRepository(ref.watch(databaseProvider)),
);
final costRepositoryProvider = Provider<CostRepository>(
  (ref) => CostRepository(ref.watch(databaseProvider)),
);
final analysisRepositoryProvider = Provider<AnalysisRepository>(
  (ref) => AnalysisRepository(ref.watch(databaseProvider)),
);
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);
final backupRepositoryProvider = Provider<BackupRepository>(
  (ref) => BackupRepository(ref.watch(databaseProvider)),
);
final seedServiceProvider = Provider<SeedService>(
  (ref) => SeedService(ref.watch(databaseProvider)),
);

final businessProvider = StreamProvider<Business?>(
  (ref) => ref.watch(businessRepositoryProvider).watchBusiness(),
);

final productsProvider = StreamProvider<List<Product>>(
  (ref) => ref.watch(menuRepositoryProvider).watchProducts(),
);

/// Hanya menu aktif, dipakai layar catat penjualan.
final activeProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  return ref
      .watch(productsProvider)
      .whenData(
        (products) => products.where((product) => product.isActive).toList(),
      );
});

/// Jendela data yang dipakai seluruh aplikasi: cukup untuk hari ini,
/// analisis 30 hari, pola mingguan, dan laporan dua bulan terakhir.
const int salesWindowDays = 90;

final recentSalesProvider = StreamProvider<List<DaySale>>((ref) {
  final from = today().subtract(const Duration(days: salesWindowDays));
  return ref.watch(salesRepositoryProvider).watchSalesSince(from);
});

final costsProvider = StreamProvider.family<List<CostItem>, String>(
  (ref, period) => ref.watch(costRepositoryProvider).watchCosts(period),
);

final settingsProvider = StreamProvider<Map<String, String>>(
  (ref) => ref.watch(settingsRepositoryProvider).watchAll(),
);

final analysisHistoryProvider = StreamProvider<List<AnalysisRecord>>(
  (ref) => ref.watch(analysisRepositoryProvider).watchAll(),
);
