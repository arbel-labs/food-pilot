import 'package:flutter_test/flutter_test.dart';

import 'package:foodpilot/shared/dates.dart';
import 'package:foodpilot/shared/format.dart';

void main() {
  group('formatRupiah', () {
    test('nol', () => expect(formatRupiah(0), 'Rp 0'));
    test('ratusan tanpa titik', () => expect(formatRupiah(500), 'Rp 500'));
    test('ribuan', () => expect(formatRupiah(15000), 'Rp 15.000'));
    test('jutaan', () => expect(formatRupiah(1234567), 'Rp 1.234.567'));
    test('negatif', () => expect(formatRupiah(-15000), '-Rp 15.000'));
  });

  group('formatRupiahCompact', () {
    test('di bawah sejuta tidak disingkat', () {
      expect(formatRupiahCompact(750000), 'Rp 750.000');
    });
    test('tepat sejuta', () => expect(formatRupiahCompact(1000000), 'Rp 1 jt'));
    test('satu desimal', () {
      expect(formatRupiahCompact(1200000), 'Rp 1,2 jt');
    });
    test('setengah dibulatkan ke atas', () {
      expect(formatRupiahCompact(1250000), 'Rp 1,3 jt');
    });
    test('naik ke miliar setelah dibulatkan', () {
      expect(formatRupiahCompact(999960000), 'Rp 1 M');
    });
    test('negatif', () {
      expect(formatRupiahCompact(-2500000), '-Rp 2,5 jt');
    });
  });

  group('formatTanggal', () {
    test('bulan pendek', () {
      expect(formatTanggal(DateTime(2026, 9, 16)), 'Rabu, 16 Sep');
    });
    test('bulan panjang', () {
      expect(
        formatTanggal(DateTime(2026, 9, 16), longMonth: true),
        'Rabu, 16 September',
      );
    });
    test('hari Minggu', () {
      expect(formatTanggal(DateTime(2026, 9, 20)), 'Minggu, 20 Sep');
    });
  });

  test('formatBulan dan formatJam', () {
    expect(formatBulan(DateTime(2026, 9)), 'September 2026');
    expect(formatJam(DateTime(2026, 9, 16, 14, 5)), '14.05');
  });

  group('formatQty', () {
    test('bulat tanpa koma', () => expect(formatQty(150), '150'));
    test('desimal memakai koma', () => expect(formatQty(0.5), '0,5'));
  });

  test('formatPercent membulatkan', () {
    expect(formatPercent(0.354), '35%');
    expect(formatPercent(-0.08), '-8%');
  });

  group('parseRupiah', () {
    test('titik ribuan diabaikan', () => expect(parseRupiah('15.000'), 15000));
    test('teks tanpa angka jadi null', () => expect(parseRupiah('abc'), isNull));
  });

  group('parseQty', () {
    test('koma dianggap desimal', () => expect(parseQty('0,5'), 0.5));
    test('titik juga diterima', () => expect(parseQty('1.5'), 1.5));
    test('kosong jadi null', () => expect(parseQty(''), isNull));
  });

  group('kunci tanggal', () {
    test('dateKey dan periodKey', () {
      expect(dateKey(DateTime(2026, 9, 6)), '2026-09-06');
      expect(periodKey(DateTime(2026, 9, 6)), '2026-09');
    });

    test('parseDateKey bolak-balik', () {
      expect(dateKey(parseDateKey('2026-01-31')), '2026-01-31');
    });

    test('periode sebelum dan sesudah melewati tahun', () {
      expect(previousPeriod('2026-01'), '2025-12');
      expect(nextPeriod('2025-12'), '2026-01');
    });
  });
}
