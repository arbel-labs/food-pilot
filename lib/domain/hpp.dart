/// Rumus modal per porsi (HPP) dan margin, CONTEXT.md bagian 4.
library;

import 'package:foodpilot/domain/models.dart';

/// Modal per porsi: Σ(qty × harga per satuan).
///
/// Dibulatkan ke rupiah terdekat karena qty boleh desimal, sedangkan uang
/// selalu `int`.
int hpp(Iterable<Ingredient> ingredients) {
  var total = 0.0;
  for (final ingredient in ingredients) {
    total += ingredient.qty * ingredient.unitPrice;
  }
  return total.round();
}

/// Margin sebagai pecahan (0,35 berarti 35%).
///
/// `null` kalau harga jual nol atau negatif, supaya tidak membagi dengan nol.
double? margin({required int sellPrice, required int cost}) {
  if (sellPrice <= 0) return null;
  return (sellPrice - cost) / sellPrice;
}

/// Laba per porsi dalam rupiah.
int profitPerUnit({required int sellPrice, required int cost}) =>
    sellPrice - cost;

/// Kelompok warna badge margin di daftar menu.
enum MarginBand { loss, thin, healthy }

/// Di bawah 0% rugi (merah), di bawah 20% tipis (amber), sisanya sehat
/// (hijau). Harga jual nol dianggap rugi.
MarginBand marginBand(double? margin) {
  if (margin == null || margin < 0) return MarginBand.loss;
  if (margin < 0.2) return MarginBand.thin;
  return MarginBand.healthy;
}
