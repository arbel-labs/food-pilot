import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:foodpilot/app/theme/app_colors.dart';
import 'package:foodpilot/app/theme/tokens.dart';
import 'package:foodpilot/data/providers.dart';
import 'package:foodpilot/domain/ai_result.dart';
import 'package:foodpilot/domain/classify.dart';
import 'package:foodpilot/features/analisis/ai_controller.dart';
import 'package:foodpilot/features/analisis/ai_service.dart';
import 'package:foodpilot/features/analisis/analisis_data.dart';
import 'package:foodpilot/shared/format.dart';
import 'package:foodpilot/shared/widgets/action_pill.dart';
import 'package:foodpilot/shared/widgets/section_card.dart';
import 'package:foodpilot/shared/widgets/skeleton.dart';
import 'package:foodpilot/shared/widgets/status_chip.dart';

/// Konsultan AI: tiga rekomendasi berformat tetap, bukan gelembung chat
/// (PRD F-08). Riwayatnya bisa dibuka ulang tanpa internet (PRD F-09).
class AiScreen extends ConsumerWidget {
  const AiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(aiControllerProvider);
    final history =
        ref.watch(analysisHistoryProvider).value ?? const <AnalysisRecord>[];
    final isDemo = ref.watch(aiServiceProvider).isDemo;
    final data = ref.watch(analisisProvider).value;
    final days = data?.daysWithData ?? 0;
    final enoughData = days >= minimumAnalysisDays;

    final record = switch (state) {
      AiShowing(:final record) => record,
      _ => history.isEmpty ? null : history.first,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Konsultan AI')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s22,
          AppSpace.s8,
          AppSpace.s22,
          AppSpace.s24,
        ),
        children: <Widget>[
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Angka dihitung di HP, AI hanya menyusun kalimatnya.',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    if (isDemo) ...<Widget>[
                      const SizedBox(width: AppSpace.s8),
                      StatusChip(
                        label: 'Mode demo',
                        background: colors.border,
                        foreground: colors.text,
                      ),
                    ],
                  ],
                ),
                if (!enoughData) ...<Widget>[
                  const SizedBox(height: AppSpace.s8),
                  Text(
                    'Butuh minimal $minimumAnalysisDays hari data. '
                    'Sekarang baru $days hari.',
                    style: textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s16),
          switch (state) {
            AiLoading() => const _LoadingCards(),
            AiFailed(:final message) => _ErrorCard(
              message: message,
              onRetry: () => unawaited(
                ref.read(aiControllerProvider.notifier).analyze(),
              ),
            ),
            _ =>
              record == null
                  ? SectionCard(
                      child: Text(
                        'Belum ada analisis. Ketuk tombol di bawah untuk '
                        'meminta tiga rekomendasi dari angka usahamu.',
                        style: textTheme.bodyMedium,
                      ),
                    )
                  : _ResultView(record: record),
          },
          if (history.length > 1) ...<Widget>[
            const SizedBox(height: AppSpace.s24),
            Text('Analisis sebelumnya', style: textTheme.titleLarge),
            const SizedBox(height: AppSpace.s12),
            for (final item in history.where((item) => item.id != record?.id))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.s8),
                child: SectionCard(
                  onTap: () =>
                      ref.read(aiControllerProvider.notifier).show(item),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.result.headline,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyLarge,
                            ),
                            Text(
                              formatTanggal(item.createdAt),
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 20,
                        color: colors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
      bottomNavigationBar: ActionPill(
        label: record == null ? 'Minta analisis' : 'Minta analisis baru',
        onPressed: state is AiLoading || !enoughData
            ? null
            : () => unawaited(ref.read(aiControllerProvider.notifier).analyze()),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.record});

  final AnalysisRecord record;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(record.result.headline, style: textTheme.headlineSmall),
        const SizedBox(height: AppSpace.s4),
        Text(
          '${formatTanggal(record.createdAt)} · periode '
          '${record.periodStart} sampai ${record.periodEnd}'
          '${record.isDemo ? ' · mode demo' : ''}',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpace.s16),
        for (final recommendation in record.result.recommendations)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.s12),
            child: _RecommendationCard(recommendation: recommendation),
          ),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.recommendation});

  final AiRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    // Prioritas bukan makna finansial, jadi warnanya tinta dan netral saja.
    final (Color background, Color foreground) =
        switch (recommendation.priority) {
          AiPriority.tinggi => (colors.ink, colors.onInk),
          AiPriority.sedang => (colors.border, colors.text),
          AiPriority.rendah => (colors.background, colors.textMuted),
        };

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              StatusChip(
                label: 'Prioritas ${recommendation.priority.name}',
                background: background,
                foreground: foreground,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s12),
          Text(recommendation.problem, style: textTheme.bodySmall),
          const SizedBox(height: AppSpace.s4),
          Text(recommendation.action, style: textTheme.bodyLarge),
          if (recommendation.impact.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpace.s8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  LucideIcons.arrowRight,
                  size: 16,
                  color: colors.textMuted,
                ),
                const SizedBox(width: AppSpace.s8),
                Expanded(
                  child: Text(
                    recommendation.impact,
                    style: textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadingCards extends StatelessWidget {
  const _LoadingCards();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SkeletonBox(height: 28, width: 220),
        const SizedBox(height: AppSpace.s16),
        for (var i = 0; i < 3; i++) ...<Widget>[
          const SkeletonBox(height: 120),
          const SizedBox(height: AppSpace.s12),
        ],
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(LucideIcons.circleAlert, size: 18, color: colors.danger),
              const SizedBox(width: AppSpace.s8),
              Expanded(child: Text(message, style: textTheme.bodyMedium)),
            ],
          ),
          const SizedBox(height: AppSpace.s8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCcw, size: 18),
              label: const Text('Coba lagi'),
            ),
          ),
        ],
      ),
    );
  }
}
