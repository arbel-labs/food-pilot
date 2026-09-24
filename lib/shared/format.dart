/// Format dan parsing teks untuk pengguna: rupiah, persen, jumlah, tanggal.
///
/// Dart murni tanpa Flutter, supaya bisa diuji cepat dengan `flutter test`.
library;

const List<String> _dayNames = <String>[
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

const List<String> _dayShort = <String>[
  'Sen',
  'Sel',
  'Rab',
  'Kam',
  'Jum',
  'Sab',
  'Min',
];

const List<String> _monthsShort = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

const List<String> _monthsLong = <String>[
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// `15000` menjadi `Rp 15.000`, `-15000` menjadi `-Rp 15.000`.
String formatRupiah(int amount) {
  final sign = amount < 0 ? '-' : '';
  return '${sign}Rp ${_groupThousands(amount.abs())}';
}

/// Ringkasan angka besar: `1200000` menjadi `Rp 1,2 jt`, `2500000000` menjadi
/// `Rp 2,5 M`. Di bawah satu juta hasilnya sama dengan [formatRupiah].
String formatRupiahCompact(int amount) {
  final value = amount.abs();
  if (value < 1000000) return formatRupiah(amount);

  // Dibulatkan ke persepuluhan dengan aritmetika int, bukan double.
  var tenths = (value + 50000) ~/ 100000;
  var unit = 'jt';
  if (tenths >= 10000) {
    tenths = (value + 50000000) ~/ 100000000;
    unit = 'M';
  }

  final whole = _groupThousands(tenths ~/ 10);
  final fraction = tenths % 10;
  final number = fraction == 0 ? whole : '$whole,$fraction';
  final sign = amount < 0 ? '-' : '';
  return '${sign}Rp $number $unit';
}

/// Pecahan menjadi persen bulat: `0.354` menjadi `35%`.
String formatPercent(double ratio) => '${(ratio * 100).round()}%';

/// Jumlah bahan: `150` menjadi `150`, `0.5` menjadi `0,5`.
String formatQty(double qty) {
  if (qty == qty.roundToDouble()) return qty.round().toString();
  final text = qty.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '');
  return text.replaceAll('.', ',');
}

/// `Rabu, 16 Sep`, atau `Rabu, 16 September` kalau [longMonth] bernilai true.
String formatTanggal(DateTime date, {bool longMonth = false}) {
  final months = longMonth ? _monthsLong : _monthsShort;
  return '${dayName(date.weekday)}, ${date.day} ${months[date.month - 1]}';
}

/// `September 2026`.
String formatBulan(DateTime date) =>
    '${_monthsLong[date.month - 1]} ${date.year}';

/// Jam gaya Indonesia: `14.30`.
String formatJam(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}.'
    '${time.minute.toString().padLeft(2, '0')}';

/// Nama hari dari `DateTime.weekday` (1 = Senin).
String dayName(int weekday) => _dayNames[weekday - 1];

/// Singkatan hari untuk grafik: `Sen`, `Sel`, dan seterusnya.
String dayShort(int weekday) => _dayShort[weekday - 1];

/// Mengambil angka rupiah dari teks isian. Titik ribuan dan huruf diabaikan.
/// Hasilnya `null` kalau tidak ada digit sama sekali.
int? parseRupiah(String text) {
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  return int.tryParse(digits);
}

/// Mengambil jumlah bahan. Koma dan titik sama-sama dianggap desimal.
double? parseQty(String text) {
  final cleaned = text.trim().replaceAll(',', '.');
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

String _groupThousands(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
