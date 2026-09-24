import 'package:flutter_test/flutter_test.dart';

import 'package:foodpilot/domain/ai_result.dart';

Map<String, Object?> rekomendasi(String action) => <String, Object?>{
  'problem': 'Masalah',
  'action': action,
  'impact': 'Dampak',
  'priority': 'tinggi',
};

void main() {
  test('menerima teks JSON', () {
    final result = AiResult.parse(
      '{"headline":"Judul","recommendations":['
      '{"problem":"a","action":"b","impact":"c","priority":"sedang"},'
      '{"problem":"a","action":"b","impact":"c","priority":"rendah"},'
      '{"problem":"a","action":"b","impact":"c","priority":"tinggi"}]}',
    );
    expect(result.headline, 'Judul');
    expect(result.recommendations, hasLength(3));
    expect(result.recommendations.first.priority, AiPriority.sedang);
  });

  test('menolak balasan yang bukan objek', () {
    expect(() => AiResult.parse('[]'), throwsFormatException);
  });

  test('menolak kalau rekomendasinya kurang dari tiga', () {
    expect(
      () => AiResult.parse(<String, Object?>{
        'headline': 'x',
        'recommendations': <Object?>[rekomendasi('a'), rekomendasi('b')],
      }),
      throwsFormatException,
    );
  });

  test('kelebihan rekomendasi dipotong jadi tiga', () {
    final result = AiResult.parse(<String, Object?>{
      'headline': 'x',
      'recommendations': <Object?>[
        rekomendasi('a'),
        rekomendasi('b'),
        rekomendasi('c'),
        rekomendasi('d'),
      ],
    });
    expect(result.recommendations, hasLength(3));
  });

  test('teks kepanjangan dipotong sesuai batas skema', () {
    final result = AiResult.parse(<String, Object?>{
      'headline': 'x' * 200,
      'recommendations': <Object?>[
        rekomendasi('a'),
        rekomendasi('b'),
        rekomendasi('c'),
      ],
    });
    expect(result.headline.length, lessThanOrEqualTo(80));
  });

  test('prioritas tidak dikenal jadi sedang', () {
    expect(AiPriority.parse('entah'), AiPriority.sedang);
  });

  test('judul kosong diganti judul bawaan', () {
    final result = AiResult.parse(<String, Object?>{
      'recommendations': <Object?>[
        rekomendasi('a'),
        rekomendasi('b'),
        rekomendasi('c'),
      ],
    });
    expect(result.headline, isNotEmpty);
  });
}
