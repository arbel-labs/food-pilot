/// Aturan validasi form menu.
///
/// Dikumpulkan di satu berkas supaya aturannya bisa dibaca sekali lihat dan
/// diuji tanpa merender widget apa pun.
library;

import 'package:foodpilot/shared/format.dart';

/// Batas atas harga jual. Di atas ini hampir pasti salah ketik, misalnya
/// menambah satu nol.
const int maxSellPrice = 10000000;

/// Nama menu: wajib, minimal tiga huruf, dan tidak boleh angka semua.
String? validateMenuName(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return 'Nama menu wajib diisi.';
  if (text.length < 3) return 'Nama menu minimal 3 karakter.';
  if (RegExp(r'^[0-9\s]+$').hasMatch(text)) {
    return 'Nama menu tidak boleh angka saja.';
  }
  return null;
}

/// Harga jual: wajib, harus angka, di atas nol, dan masuk akal.
String? validateSellPrice(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return 'Harga jual wajib diisi.';
  final price = parseRupiah(text);
  if (price == null) return 'Harga jual harus berupa angka.';
  if (price <= 0) return 'Harga jual harus lebih dari nol.';
  if (price > maxSellPrice) {
    return 'Harga jual terlalu besar. Cek lagi angkanya.';
  }
  return null;
}

/// Nama bahan: wajib, minimal dua huruf.
String? validateIngredientName(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return 'Nama bahan wajib diisi.';
  if (text.length < 2) return 'Nama bahan terlalu pendek.';
  return null;
}

/// Jumlah bahan: wajib, harus angka, dan di atas nol.
String? validateQty(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return 'Jumlah wajib diisi.';
  final qty = parseQty(text);
  if (qty == null) return 'Jumlah harus angka.';
  if (qty <= 0) return 'Jumlah harus lebih dari nol.';
  return null;
}

/// Harga per satuan: wajib dan harus angka. Nol diperbolehkan, misalnya
/// untuk bahan yang tidak dihitung biayanya.
String? validateUnitPrice(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return 'Harga wajib diisi.';
  if (parseRupiah(text) == null) return 'Harga harus berupa angka.';
  return null;
}

/// Tautan gambar: boleh kosong, tapi kalau diisi harus berupa URL http.
String? validateImageUrl(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return null;

  final uri = Uri.tryParse(text);
  if (uri == null || !uri.hasAbsolutePath && !uri.hasAuthority) {
    return 'Tautan gambar tidak valid.';
  }
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    return 'Tautan harus diawali http:// atau https://';
  }
  if (uri.host.isEmpty) return 'Tautan gambar tidak lengkap.';
  return null;
}