import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:foodpilot/core/setting_keys.dart';
import 'package:foodpilot/data/providers.dart';
import 'package:foodpilot/data/repositories/sales_repository.dart';
import 'package:foodpilot/domain/models.dart';
import 'package:foodpilot/shared/dates.dart';

class CatatState {
  const CatatState({
    required this.date,
    required this.quantities,
    required this.loading,
    this.savedAt,
  });

  final DateTime date;
  final Map<String, int> quantities;
  final bool loading;

  /// Jam penyimpanan terakhir untuk tanggal ini, kalau sudah pernah disimpan.
  final DateTime? savedAt;

  bool get isUpdate => savedAt != null;

  int get totalQty {
    var total = 0;
    for (final qty in quantities.values) {
      total += qty;
    }
    return total;
  }

  int qtyOf(String productId) => quantities[productId] ?? 0;

  int totalRupiah(List<Product> products) {
    var total = 0;
    for (final product in products) {
      total += product.sellPrice * qtyOf(product.id);
    }
    return total;
  }

  CatatState copyWith({Map<String, int>? quantities, DateTime? savedAt}) {
    return CatatState(
      date: date,
      quantities: quantities ?? this.quantities,
      loading: loading,
      savedAt: savedAt ?? this.savedAt,
    );
  }
}

/// Draf catat penjualan.
///
/// State Riverpod bertahan saat modal ditutup tanpa sengaja, tapi hilang
/// kalau sistem mematikan aplikasi. Karena itu draf juga ditulis ke tabel
/// app_settings setiap kali berubah (DESAIN-catat.md).
class CatatController extends Notifier<CatatState> {
  @override
  CatatState build() => CatatState(
    date: today(),
    quantities: const <String, int>{},
    loading: true,
  );

  Future<void> open(DateTime date) async {
    state = CatatState(
      date: date,
      quantities: const <String, int>{},
      loading: true,
    );

    final existing = await ref
        .read(salesRepositoryProvider)
        .getSaleForDate(date);
    final draft = await _readDraft(date);

    state = CatatState(
      date: date,
      quantities:
          draft ??
          <String, int>{
            if (existing != null)
              for (final line in existing.lines) line.productId: line.qty,
          },
      loading: false,
      savedAt: existing?.updatedAt,
    );
  }

  void increment(String productId) =>
      _setQty(productId, state.qtyOf(productId) + 1);

  void decrement(String productId) =>
      _setQty(productId, state.qtyOf(productId) - 1);

  void setQty(String productId, int qty) => _setQty(productId, qty);

  Future<UndoToken> save(List<Product> products) async {
    final token = await ref
        .read(salesRepositoryProvider)
        .saveSale(
          date: state.date,
          quantities: state.quantities,
          products: products,
        );
    await ref.read(settingsRepositoryProvider).remove(SettingKeys.catatDraft);
    state = state.copyWith(savedAt: DateTime.now());
    return token;
  }

  void _setQty(String productId, int qty) {
    final quantities = <String, int>{...state.quantities};
    if (qty <= 0) {
      quantities.remove(productId);
    } else {
      quantities[productId] = qty;
    }
    state = state.copyWith(quantities: quantities);
    unawaited(_writeDraft());
  }

  Future<Map<String, int>?> _readDraft(DateTime date) async {
    final raw = await ref.read(settingsRepositoryProvider).get(
      SettingKeys.catatDraft,
    );
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map || json['tanggal'] != dateKey(date)) return null;
      final quantities = json['jumlah'];
      if (quantities is! Map) return null;
      return <String, int>{
        for (final entry in quantities.entries)
          if (entry.key is String && entry.value is int)
            entry.key as String: entry.value as int,
      };
    } on FormatException {
      return null;
    }
  }

  Future<void> _writeDraft() async {
    final settings = ref.read(settingsRepositoryProvider);
    if (state.quantities.isEmpty) {
      await settings.remove(SettingKeys.catatDraft);
      return;
    }
    await settings.set(
      SettingKeys.catatDraft,
      jsonEncode(<String, Object?>{
        'tanggal': dateKey(state.date),
        'jumlah': state.quantities,
      }),
    );
  }
}

final catatControllerProvider = NotifierProvider<CatatController, CatatState>(
  CatatController.new,
);

/// Menu untuk layar catat. Di atas 12 menu, urutannya mengikuti frekuensi
/// penjualan 30 hari terakhir supaya yang sering laku ada di layar pertama.
final catatProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final products = ref.watch(activeProductsProvider);
  final sales = ref.watch(recentSalesProvider).value ?? const <DaySale>[];

  return products.whenData((list) {
    if (list.length <= 12) return list;
    final from = today().subtract(const Duration(days: 30));
    final counts = <String, int>{};
    for (final sale in sales) {
      if (sale.date.isBefore(from)) continue;
      for (final line in sale.lines) {
        counts[line.productId] = (counts[line.productId] ?? 0) + line.qty;
      }
    }
    return <Product>[...list]
      ..sort((a, b) => (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0));
  });
});
