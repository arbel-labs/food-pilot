/// Kunci tanggal dan periode sebagai teks yang aman diurutkan.
///
/// Dart murni tanpa Flutter.
library;

/// `2026-09-16`.
String dateKey(DateTime date) =>
    '${_four(date.year)}-${_two(date.month)}-${_two(date.day)}';

/// `2026-09`.
String periodKey(DateTime date) => '${_four(date.year)}-${_two(date.month)}';

/// Hari ini jam 00.00 waktu lokal.
DateTime today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime parseDateKey(String key) {
  final parts = key.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

/// Tanggal pertama sebuah periode `YYYY-MM`.
DateTime periodStart(String period) {
  final parts = period.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]));
}

/// `2026-01` menjadi `2025-12`.
String previousPeriod(String period) {
  final start = periodStart(period);
  return periodKey(DateTime(start.year, start.month - 1));
}

/// `2025-12` menjadi `2026-01`.
String nextPeriod(String period) {
  final start = periodStart(period);
  return periodKey(DateTime(start.year, start.month + 1));
}

String _two(int value) => value.toString().padLeft(2, '0');
String _four(int value) => value.toString().padLeft(4, '0');
