import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:foodpilot/app/theme/app_colors.dart';
import 'package:foodpilot/app/theme/brand.dart';
import 'package:foodpilot/app/theme/tokens.dart';
import 'package:foodpilot/domain/classify.dart';
import 'package:foodpilot/features/analisis/analisis_data.dart';
import 'package:foodpilot/features/analisis/weekly_chart.dart';
import 'package:foodpilot/shared/format.dart';
import 'package:foodpilot/shared/widgets/async_view.dart';
import 'package:foodpilot/shared/widgets/empty_state.dart';
import 'package:foodpilot/shared/widgets/icon_box.dart';
import 'package:foodpilot/shared/widgets/link_list_card.dart';
import 'package:foodpilot/shared/widgets/pill_tab_bar.dart';
import 'package:foodpilot/shared/widgets/section_card.dart';

/// Tiga kelompok menu berbahasa awam, pola mingguan, dan pintu ke konsultan
/// AI serta simulasi harga (PRD F-06, F-07, F-10).
class AnalisisScreen extends ConsumerWidget {
  const AnalisisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final data = ref.watch(analisisProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analisis')),
      body: AsyncView<AnalisisData?>(
        value: data,
        builder: (value) {
          if (value == null) {
            return const EmptyState(
              icon: LucideIcons.chartColumn,
              title: 'Belum ada data usaha',
              message: 'Isi data usaha dulu lewat onboarding.',
            );
          }

          return ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpace.s22,
              AppSpace.s8,
              AppSpace.s22,
              bottomChromeClearance(context),
            ),
            children: <Widget>[
              Text(
                '${formatTanggal(value.from)} sampai ${formatTanggal(value.to)}',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpace.s16),
              switch (value.analysis) {
                MenuAnalysisNotEnoughData(:final days) => _NotEnoughData(
                  days: days,
                ),
                MenuAnalysisReady(:final items) => _Groups(
                  items: items,
                  unitWord: value.business.type.unitWord,
                ),
              },
              const SizedBox(height: AppSpace.s24),
              const _SectionHeading(
                icon: LucideIcons.calendarDays,
                label: 'Pola mingguan',
              ),
              const SizedBox(height: AppSpace.s12),
              SectionCard(child: WeeklyChart(pattern: value.pattern)),
              const SizedBox(height: AppSpace.s24),
              LinkListCard(
                items: <LinkItem>[
                  LinkItem(
                    icon: LucideIcons.sparkles,
                    title: 'Konsultan AI',
                    subtitle: 'Tiga rekomendasi dari angka usahamu',
                    onTap: () => context.push('/analisis/ai'),
                  ),
                  LinkItem(
                    icon: LucideIcons.sliders,
                    title: 'Simulasi harga',
                    subtitle: 'Geser harga jual dan harga bahan',
                    onTap: () => context.push('/analisis/simulasi'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Judul bagian dengan ikon mungil di kiri.
class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: colors.textMuted),
        const SizedBox(width: AppSpace.s8),
        Text(label, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _NotEnoughData extends StatelessWidget {
  const _NotEnoughData({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;
    final textTheme = Theme.of(context).textTheme;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconBox(
                icon: LucideIcons.hourglass,
                background: brand.brandTint,
                foreground: brand.brand,
              ),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: Text('Data belum cukup', style: textTheme.titleLarge),
              ),
              Text(
                '$days/$minimumAnalysisDays',
                style: AppSerif.number.copyWith(color: colors.text),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpace.s4),
            child: LinearProgressIndicator(
              value: days / minimumAnalysisDays,
              minHeight: 6,
              backgroundColor: colors.border,
              valueColor: AlwaysStoppedAnimation<Color>(brand.brand),
            ),
          ),
          const SizedBox(height: AppSpace.s12),
          Text(
            'Analisis menu butuh minimal $minimumAnalysisDays hari penjualan. '
            'Sekarang baru $days hari tercatat.',
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _Groups extends StatelessWidget {
  const _Groups({required this.items, required this.unitWord});

  final List<MenuPerformance> items;
  final String unitWord;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final entry
            in <(MenuClass, Color, Color, IconData)>[
              (
                MenuClass.mainContributor,
                colors.success,
                brand.successTint,
                LucideIcons.trendingUp,
              ),
              (
                MenuClass.popularThin,
                colors.warning,
                brand.warningTint,
                LucideIcons.minus,
              ),
              (
                MenuClass.drain,
                colors.danger,
                brand.dangerTint,
                LucideIcons.trendingDown,
              ),
            ])
          _Group(
            menuClass: entry.$1,
            color: entry.$2,
            tint: entry.$3,
            icon: entry.$4,
            items: items.where((item) => item.menuClass == entry.$1).toList(),
            unitWord: unitWord,
          ),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.menuClass,
    required this.color,
    required this.tint,
    required this.icon,
    required this.items,
    required this.unitWord,
  });

  final MenuClass menuClass;
  final Color color;
  final Color tint;
  final IconData icon;
  final List<MenuPerformance> items;
  final String unitWord;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              // Titik bulat diganti kotak ikon supaya kelompoknya terbaca
              // lewat bentuk, bukan warna saja.
              IconBox(
                icon: icon,
                background: tint,
                foreground: color,
                size: 30,
              ),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: Text(menuClass.label, style: textTheme.titleMedium),
              ),
              if (items.isNotEmpty)
                Text('${items.length}', style: textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpace.s8),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 42),
              child: Text(
                'Tidak ada menu di kelompok ini.',
                style: textTheme.bodySmall,
              ),
            )
          else
            SectionCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  for (var i = 0; i < items.length; i++) ...<Widget>[
                    if (i > 0) const Divider(height: 1),
                    _MenuDetail(item: items[i], unitWord: unitWord),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Tiap item bisa dibuka untuk melihat rumusnya (PRD F-06).
class _MenuDetail extends StatelessWidget {
  const _MenuDetail({required this.item, required this.unitWord});

  final MenuPerformance item;
  final String unitWord;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final averagePrice = item.qty == 0 ? 0 : (item.revenue / item.qty).round();
    final averageCost = item.qty == 0
        ? 0
        : ((item.revenue - item.grossProfit) / item.qty).round();

    return ExpansionTile(
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: const EdgeInsets.symmetric(horizontal: AppSpace.s16),
      childrenPadding: const EdgeInsets.fromLTRB(
        AppSpace.s16,
        0,
        AppSpace.s16,
        AppSpace.s16,
      ),
      title: Text(item.name, style: textTheme.bodyLarge),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpace.s4),
        child: Row(
          children: <Widget>[
            Text(
              formatRupiahCompact(item.grossProfit),
              style: AppSerif.number.copyWith(fontSize: 17, color: colors.text),
            ),
            const SizedBox(width: AppSpace.s8),
            Expanded(
              child: Text(
                'laba · ${item.qty} $unitWord',
                style: textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
      children: <Widget>[
        _FormulaLine(
          label: 'Rata-rata harga jual',
          value: formatRupiah(averagePrice),
        ),
        _FormulaLine(
          label: 'Rata-rata modal per $unitWord',
          value: formatRupiah(averageCost),
        ),
        _FormulaLine(
          label: 'Pendapatan = harga × terjual',
          value: formatRupiah(item.revenue),
        ),
        _FormulaLine(
          label: 'Laba kotor = (harga − modal) × terjual',
          value: formatRupiah(item.grossProfit),
        ),
        _FormulaLine(
          label: 'Margin = laba kotor ÷ pendapatan',
          value: formatPercent(item.margin),
        ),
        _FormulaLine(
          label: 'Kontribusi = laba menu ÷ laba semua menu',
          value: formatPercent(item.contribution),
        ),
      ],
    );
  }
}

class _FormulaLine extends StatelessWidget {
  const _FormulaLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: Text(label, style: textTheme.bodySmall)),
          const SizedBox(width: AppSpace.s8),
          Text(value, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}