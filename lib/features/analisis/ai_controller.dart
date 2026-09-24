import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:foodpilot/data/providers.dart';
import 'package:foodpilot/domain/ai_result.dart';
import 'package:foodpilot/features/analisis/ai_service.dart';
import 'package:foodpilot/features/analisis/analisis_data.dart';

sealed class AiState {
  const AiState();
}

final class AiIdle extends AiState {
  const AiIdle();
}

final class AiLoading extends AiState {
  const AiLoading();
}

final class AiShowing extends AiState {
  const AiShowing(this.record);

  final AnalysisRecord record;
}

final class AiFailed extends AiState {
  const AiFailed(this.message);

  final String message;
}

/// Batas tunggu sesuai CONTEXT.md bagian 6.
const Duration aiTimeout = Duration(seconds: 15);

class AiController extends Notifier<AiState> {
  @override
  AiState build() => const AiIdle();

  void show(AnalysisRecord record) => state = AiShowing(record);

  Future<void> analyze() async {
    state = const AiLoading();
    final service = ref.read(aiServiceProvider);

    try {
      final summary = await ref.read(aiSummaryProvider.future);
      if (summary == null) {
        state = const AiFailed('Data usaha belum ada.');
        return;
      }

      final result = await service.analyze(summary.payload).timeout(aiTimeout);
      final record = await ref
          .read(analysisRepositoryProvider)
          .save(
            periodStart: summary.periodStart,
            periodEnd: summary.periodEnd,
            input: summary.payload,
            result: result,
            isDemo: service.isDemo,
          );
      state = AiShowing(record);
    } on TimeoutException {
      state = const AiFailed(
        'Tidak ada balasan dalam 15 detik. Periksa koneksi, lalu coba lagi.',
      );
    } on SocketException {
      state = const AiFailed(
        'Tidak bisa menghubungi server. Aplikasi tetap bisa dipakai tanpa '
        'internet, dan mode demo ada di Pengaturan.',
      );
    } on AiException catch (error) {
      state = AiFailed(error.message);
    } on FormatException {
      state = const AiFailed(
        'Balasan AI tidak sesuai format. Coba lagi sebentar.',
      );
    } catch (error) {
      state = AiFailed('Analisis gagal: $error');
    }
  }
}

final aiControllerProvider = NotifierProvider<AiController, AiState>(
  AiController.new,
);
