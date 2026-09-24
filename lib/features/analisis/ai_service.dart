import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:foodpilot/core/config.dart';
import 'package:foodpilot/core/setting_keys.dart';
import 'package:foodpilot/data/providers.dart';
import 'package:foodpilot/domain/ai_result.dart';

class AiException implements Exception {
  const AiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Kunci API tidak pernah ada di aplikasi. Aplikasi hanya memanggil Edge
/// Function, dan function itu yang memanggil Gemini (CONTEXT.md bagian 6).
abstract interface class AiService {
  bool get isDemo;

  Future<AiResult> analyze(Map<String, Object?> summary);

  Future<String> caption({
    required String businessName,
    required String menuName,
    required int price,
  });
}

class SupabaseAiService implements AiService {
  const SupabaseAiService();

  @override
  bool get isDemo => false;

  @override
  Future<AiResult> analyze(Map<String, Object?> summary) async {
    final data = await _invoke(<String, Object?>{
      'mode': 'analisis',
      'ringkasan': summary,
    });
    return AiResult.parse(data);
  }

  @override
  Future<String> caption({
    required String businessName,
    required String menuName,
    required int price,
  }) async {
    final data = await _invoke(<String, Object?>{
      'mode': 'caption',
      'menu': <String, Object?>{
        'usaha': businessName,
        'nama': menuName,
        'harga': price,
      },
    });
    if (data is Map && data['caption'] is String) {
      return data['caption'] as String;
    }
    throw const AiException('Balasan caption tidak bisa dibaca.');
  }

  Future<Object?> _invoke(Map<String, Object?> body) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'analyze',
        body: body,
      );
      if (response.status >= 400) {
        throw AiException(
          'Server AI menolak permintaan (kode ${response.status}).',
        );
      }
      return response.data;
    } on FunctionException catch (error) {
      throw AiException(
        'Server AI menolak permintaan (kode ${error.status}). '
        'Pastikan function analyze sudah di-deploy.',
      );
    }
  }
}

/// Mode demo: balasan tersimpan, dipakai saat Supabase belum dikonfigurasi,
/// saat kuota habis, atau saat demo di kelas tanpa internet.
class DemoAiService implements AiService {
  const DemoAiService();

  @override
  bool get isDemo => true;

  @override
  Future<AiResult> analyze(Map<String, Object?> summary) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final names = <String, String>{};
    final menus = summary['menu'];
    if (menus is List) {
      for (final item in menus) {
        if (item is Map) {
          final group = item['kelompok'];
          final name = item['nama'];
          if (group is String && name is String) {
            names.putIfAbsent(group, () => name);
          }
        }
      }
    }

    final best = names['Penyumbang laba utama'] ?? 'menu andalan';
    final thin = names['Laku tapi tipis'] ?? 'menu yang marginnya tipis';
    final drain = names['Menguras tanpa hasil'] ?? 'menu yang jarang laku';

    return AiResult(
      headline: 'Tiga langkah untuk minggu ini (mode demo)',
      recommendations: <AiRecommendation>[
        AiRecommendation(
          problem: '$best paling banyak menyumbang laba.',
          action:
              'Pastikan bahan $best tidak pernah habis, terutama menjelang '
              'akhir pekan. Tawarkan menu ini lebih dulu ke pembeli yang '
              'masih bingung memilih.',
          impact: 'Laba harian lebih stabil.',
          priority: AiPriority.tinggi,
        ),
        AiRecommendation(
          problem: '$thin laku, tapi sisa untungnya tipis.',
          action:
              'Cek ulang harga bahan $thin minggu ini, atau naikkan harga '
              'jualnya Rp 1.000 dan lihat apakah jumlah pembeli tetap.',
          impact: 'Margin naik tanpa kehilangan pelanggan.',
          priority: AiPriority.sedang,
        ),
        AiRecommendation(
          problem: '$drain jarang laku dan menahan modal bahan.',
          action:
              'Coba hentikan $drain selama satu minggu, lalu bandingkan laba '
              'bersih harian sebelum dan sesudahnya.',
          impact: 'Modal bahan berkurang, dapur lebih ringkas.',
          priority: AiPriority.rendah,
        ),
      ],
    );
  }

  @override
  Future<String> caption({
    required String businessName,
    required String menuName,
    required int price,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return 'Hari ini masak $menuName lagi di $businessName. '
        'Masih hangat, harga tetap. Mampir sebelum kehabisan ya. '
        '#$businessName #kulinerlokal';
  }
}

final aiServiceProvider = Provider<AiService>((ref) {
  final settings = ref.watch(settingsProvider).value ?? const <String, String>{};
  final demoSetting = settings[SettingKeys.aiDemo] == 'true';
  if (!AppConfig.hasSupabase || demoSetting) return const DemoAiService();
  return const SupabaseAiService();
});
