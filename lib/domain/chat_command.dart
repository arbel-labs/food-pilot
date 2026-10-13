/// Hasil penafsiran kalimat pemilik oleh AI.
///
/// AI hanya menerjemahkan bahasa menjadi data. Seluruh perhitungan modal
/// dan margin tetap dikerjakan lapisan domain (CONTEXT.md bagian 6), jadi
/// tidak ada kolom hasil hitungan di sini.
library;

import 'dart:convert';

/// Satu baris bahan hasil tangkapan dari kalimat pemilik.
class ChatIngredient {
  const ChatIngredient({required this.name, required this.price});

  final String name;

  /// Harga bahan untuk satu porsi, dalam rupiah.
  final int price;
}

sealed class ChatCommand {
  const ChatCommand();

  /// Parsing defensif: bentuk yang tidak dikenali tidak dilempar sebagai
  /// error, tapi diturunkan jadi [ChatUnknown] supaya layar chat tetap
  /// bisa menampilkan sesuatu yang masuk akal.
  factory ChatCommand.parse(Object? data) {
    var json = data;
    if (json is String) json = jsonDecode(json);
    if (json is! Map) {
      return const ChatUnknown('Balasan tidak bisa dibaca. Coba tulis ulang.');
    }

    switch (json['aksi']) {
      case 'tambah_menu':
        final name = _text(json['nama'], 60);
        final price = _money(json['harga_jual']);
        if (name.isEmpty) {
          return const ChatUnknown('Nama menunya belum kebaca. Coba tulis ulang.');
        }
        final rawIngredients = json['bahan'];
        return ChatAddMenu(
          name: name,
          sellPrice: price,
          ingredients: <ChatIngredient>[
            if (rawIngredients is List)
              for (final item in rawIngredients)
                if (item is Map && _text(item['nama'], 40).isNotEmpty)
                  ChatIngredient(
                    name: _text(item['nama'], 40),
                    price: _money(item['harga']),
                  ),
          ],
        );

      case 'tanya':
        final question = _text(json['pertanyaan'], 120);
        return ChatAsk(
          question.isEmpty ? 'Boleh diperjelas lagi?' : question,
        );

      default:
        final message = _text(json['pesan'], 160);
        return ChatUnknown(
          message.isEmpty
              ? 'Aku belum paham. Coba tulis seperti ini: tambah es teh 5 rb, '
                  'bahannya teh 500 sama gula 300.'
              : message,
        );
    }
  }
}

/// Draf menu baru yang menunggu konfirmasi pemilik.
final class ChatAddMenu extends ChatCommand {
  const ChatAddMenu({
    required this.name,
    required this.sellPrice,
    required this.ingredients,
  });

  final String name;
  final int sellPrice;
  final List<ChatIngredient> ingredients;

  /// Modal per porsi, dijumlah di sini supaya angkanya tidak pernah
  /// berasal dari AI.
  int get cost {
    var total = 0;
    for (final item in ingredients) {
      total += item.price;
    }
    return total;
  }

  int get profit => sellPrice - cost;

  /// Null kalau harga jual nol, supaya pembagian nol tidak pernah terjadi.
  double? get margin => sellPrice <= 0 ? null : profit / sellPrice;

  ChatAddMenu copyWith({
    String? name,
    int? sellPrice,
    List<ChatIngredient>? ingredients,
  }) {
    return ChatAddMenu(
      name: name ?? this.name,
      sellPrice: sellPrice ?? this.sellPrice,
      ingredients: ingredients ?? this.ingredients,
    );
  }
}

/// AI butuh satu keterangan lagi sebelum bisa menyusun draf.
final class ChatAsk extends ChatCommand {
  const ChatAsk(this.question);

  final String question;
}

/// Kalimatnya di luar jangkauan, atau balasannya tidak terbaca.
final class ChatUnknown extends ChatCommand {
  const ChatUnknown(this.message);

  final String message;
}

String _text(Object? value, int max) {
  final text = value is String ? value.trim() : '';
  if (text.length <= max) return text;
  return '${text.substring(0, max - 1).trimRight()}…';
}

int _money(Object? value) {
  if (value is int) return value < 0 ? 0 : value;
  if (value is num) return value < 0 ? 0 : value.round();
  if (value is String) return int.tryParse(value.trim()) ?? 0;
  return 0;
}