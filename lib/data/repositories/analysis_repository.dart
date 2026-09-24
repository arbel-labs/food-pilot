import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:foodpilot/core/ids.dart';
import 'package:foodpilot/data/database.dart';
import 'package:foodpilot/domain/ai_result.dart';

class AnalysisRepository {
  AnalysisRepository(this._db);

  final AppDatabase _db;

  /// Riwayat analisis, terbaru di atas. Tersimpan lokal, bisa dibuka ulang
  /// tanpa internet (PRD F-09).
  Stream<List<AnalysisRecord>> watchAll() {
    final query = _db.select(_db.aiAnalyses)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(30);
    return query.watch().map(
      (rows) => <AnalysisRecord>[
        for (final row in rows)
          ?_tryParse(row),
      ],
    );
  }

  Future<AnalysisRecord> save({
    required String periodStart,
    required String periodEnd,
    required Map<String, Object?> input,
    required AiResult result,
    required bool isDemo,
  }) async {
    final businessId = await _businessId();
    final id = newId();
    final createdAt = nowMillis();
    final summary = <String, Object?>{...input, 'mode_demo': isDemo};

    await _db
        .into(_db.aiAnalyses)
        .insert(
          AiAnalysesCompanion.insert(
            id: id,
            businessId: businessId,
            periodStart: periodStart,
            periodEnd: periodEnd,
            inputSummary: jsonEncode(summary),
            result: jsonEncode(result.toJson()),
            createdAt: createdAt,
          ),
        );

    return AnalysisRecord(
      id: id,
      periodStart: periodStart,
      periodEnd: periodEnd,
      result: result,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      isDemo: isDemo,
    );
  }

  /// Baris rusak dilewati, bukan membuat seluruh riwayat gagal dimuat.
  AnalysisRecord? _tryParse(AiAnalysisRow row) {
    try {
      final input = jsonDecode(row.inputSummary);
      return AnalysisRecord(
        id: row.id,
        periodStart: row.periodStart,
        periodEnd: row.periodEnd,
        result: AiResult.parse(jsonDecode(row.result)),
        createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
        isDemo: input is Map && input['mode_demo'] == true,
      );
    } on FormatException {
      return null;
    }
  }

  Future<String> _businessId() async {
    final row = await (_db.select(_db.businesses)..limit(1)).getSingleOrNull();
    if (row == null) {
      throw StateError('Data usaha belum ada, analisis tidak bisa disimpan.');
    }
    return row.id;
  }
}
