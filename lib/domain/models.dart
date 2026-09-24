/// Model aplikasi. Dart murni, dipakai oleh domain, repository, dan UI.
library;

enum BusinessType {
  kuliner('Kuliner', 'porsi'),
  fashion('Fashion', 'pcs'),
  jasa('Jasa', 'layanan');

  const BusinessType(this.label, this.unitWord);

  final String label;

  /// Kata satuan terjual: "8 porsi terjual", "8 pcs terjual".
  final String unitWord;

  static BusinessType fromId(String id) {
    return BusinessType.values.firstWhere(
      (type) => type.name == id,
      orElse: () => BusinessType.kuliner,
    );
  }
}

class Business {
  const Business({
    required this.id,
    required this.name,
    required this.type,
    this.openTime,
    this.closeTime,
    this.operatingDays = 30,
  });

  final String id;
  final String name;
  final BusinessType type;
  final String? openTime;
  final String? closeTime;
  final int operatingDays;
}

enum IngredientUnit {
  gram('gram'),
  ml('ml'),
  pcs('pcs'),
  sdm('sdm');

  const IngredientUnit(this.label);

  final String label;

  static IngredientUnit fromId(String id) {
    return IngredientUnit.values.firstWhere(
      (unit) => unit.name == id,
      orElse: () => IngredientUnit.pcs,
    );
  }
}

class Ingredient {
  const Ingredient({
    required this.id,
    required this.name,
    required this.qty,
    required this.unit,
    required this.unitPrice,
  });

  final String id;
  final String name;

  /// Jumlah bahan per porsi, boleh desimal.
  final double qty;
  final IngredientUnit unit;

  /// Rupiah per satuan.
  final int unitPrice;
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.sellPrice,
    required this.ingredients,
    this.category,
    this.isActive = true,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String? category;
  final int sellPrice;
  final bool isActive;
  final int sortOrder;
  final List<Ingredient> ingredients;
}

/// Satu baris penjualan dengan snapshot harga dan modal saat transaksi.
class SaleLine {
  const SaleLine({
    required this.productId,
    required this.productName,
    required this.qty,
    required this.unitPrice,
    required this.unitCost,
  });

  final String productId;
  final String productName;
  final int qty;
  final int unitPrice;
  final int unitCost;
}

class DaySale {
  const DaySale({
    required this.id,
    required this.date,
    required this.lines,
    required this.updatedAt,
  });

  final String id;
  final DateTime date;
  final List<SaleLine> lines;
  final DateTime updatedAt;
}

class CostItem {
  const CostItem({
    required this.id,
    required this.period,
    required this.name,
    required this.amount,
  });

  final String id;

  /// `YYYY-MM`.
  final String period;
  final String name;
  final int amount;
}
