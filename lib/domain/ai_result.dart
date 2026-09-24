/// Balasan konsultan AI dan parsing defensifnya (CONTEXT.md bagian 6).
library;

import 'dart:convert';

enum AiPriority {
  tinggi,
  sedang,
  rendah;

  static AiPriority parse(Object? value) {
    final text = value is String ? value.trim().toLowerCase() : '';
    return AiPriority.values.firstWhere(
      (priority) => priority.name == text,
      orElse: () => AiPriority.sedang,
    );
  }
}

class AiRecommendation {
  const AiRecommendation({
    required this.problem,
    required this.action,
    required this.impact,
    required this.priority,
  });

  factory AiRecommendation.parse(Object? json) {
    if (json is! Map) {
      throw const FormatException('Rekomendasi AI bukan objek JSON');
    }
    final action = _text(json['action'], 200);
    if (action.isEmpty) {
      throw const FormatException('Rekomendasi AI tidak berisi tindakan');
    }
    return AiRecommendation(
      problem: _text(json['problem'], 120),
      action: action,
      impact: _text(json['impact'], 100),
      priority: AiPriority.parse(json['priority']),
    );
  }

  final String problem;
  final String action;
  final String impact;
  final AiPriority priority;

  Map<String, Object?> toJson() => <String, Object?>{
    'problem': problem,
    'action': action,
    'impact': impact,
    'priority': priority.name,
  };
}

class AiResult {
  const AiResult({required this.headline, required this.recommendations});

  /// Menerima Map atau teks JSON. Teks dipotong sesuai batas skema, dan
  /// hasilnya ditolak kalau tidak berisi tiga rekomendasi.
  factory AiResult.parse(Object? data) {
    var json = data;
    if (json is String) json = jsonDecode(json);
    if (json is! Map) {
      throw const FormatException('Balasan AI bukan objek JSON');
    }
    final recommendations = json['recommendations'];
    if (recommendations is! List || recommendations.length < 3) {
      throw const FormatException('Balasan AI tidak berisi tiga rekomendasi');
    }
    final headline = _text(json['headline'], 80);
    return AiResult(
      headline: headline.isEmpty ? 'Tiga langkah untuk minggu ini' : headline,
      recommendations: <AiRecommendation>[
        for (final item in recommendations.take(3)) AiRecommendation.parse(item),
      ],
    );
  }

  final String headline;
  final List<AiRecommendation> recommendations;

  Map<String, Object?> toJson() => <String, Object?>{
    'headline': headline,
    'recommendations': <Object?>[
      for (final item in recommendations) item.toJson(),
    ],
  };
}

/// Satu analisis yang tersimpan di tabel `ai_analyses`.
class AnalysisRecord {
  const AnalysisRecord({
    required this.id,
    required this.periodStart,
    required this.periodEnd,
    required this.result,
    required this.createdAt,
    required this.isDemo,
  });

  final String id;
  final String periodStart;
  final String periodEnd;
  final AiResult result;
  final DateTime createdAt;
  final bool isDemo;
}

String _text(Object? value, int max) {
  final text = value is String ? value.trim() : '';
  if (text.length <= max) return text;
  return '${text.substring(0, max - 1).trimRight()}…';
}
