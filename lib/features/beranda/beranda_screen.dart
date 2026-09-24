import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:foodpilot/app/theme/app_colors.dart';
import 'package:foodpilot/app/theme/app_theme.dart';
import 'package:foodpilot/app/theme/tokens.dart';
import 'package:foodpilot/domain/breakeven.dart';
import 'package:foodpilot/features/beranda/beranda_data.dart';
import 'package:foodpilot/shared/format.dart';
import 'package:foodpilot/shared/widgets/async_view.dart';
import 'package:foodpilot/shared/widgets/empty_state.dart';
import 'package:foodpilot/shared/widgets/pill_tab_bar.dart';
import 'package:foodpilot/shared/widgets/section_card.dart';
import 'package:foodpilot/shared/widgets/stat_tile.dart';
import 'package:foodpilot/shared/widgets/status_chip.dart';

/// Satu layar tanpa scroll: laba bersih hari ini, progress balik modal, dan
/// tiga menu terlaris (PRD F-05).
class BerandaScreen extends ConsumerWidget {
  const BerandaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final data = ref.watch(berandaProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ref.watch(berandaProvider).value?.business.name ?? 'FoodPilot',
        ),
      ),
      body: AsyncView<BerandaData?>(
        value: data,
        builder: (value) {
          if (value == null) {
            return const EmptyState(
              icon: LucideIcons.store,
              title: 'Belum ada data usaha',
              message: 'Isi data usaha dulu lewat onboarding.',
            );
          }

          final net = value.net;
          final netColor = net.value > 0
              ? colors.success
              : net.value < 0
              ? colors.danger
              : colors.text;

          return ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpace.s22,
              AppSpace.s8,
              AppSpace.s22,
              bottomChromeClearance(context),
            ),
            children: <Widget>[
              Text(formatTanggal(value.date), style: textTheme.bodySmall),
              const SizedBox(height: AppSpace.s24),
              Row(
                children: <Widget>[
                  Text('Laba bersih hari ini', style: textTheme.bodyMedium),
                  const SizedBox(width: AppSpace.s8),
                  if (net.isEstimate)
                    StatusChip(
                      label: 'estimasi',
                      background: colors.border,
                      foreground: colors.textMuted,
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.s4),
              Text(
                formatRupiah(net.value),
                style: AppType.bigNumber.copyWith(color: netColor),
              ),
              const SizedBox(height: AppSpace.s8),
              Text(
                value.costsFilled
                    ? 'Laba kotor dikurangi biaya tetap '
                          '${formatRupiah(value.dailyFixed)} per hari.'
                    : 'Biaya operasional belum diisi, jadi angka ini masih '
                          'laba kotor.',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpace.s24),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: StatTile(
                        value: formatRupiahCompact(value.revenue),
                        label: 'Pendapatan hari ini',
                      ),
                    ),
                    const SizedBox(width: AppSpace.s8),
                    Expanded(
                      child: StatTile(
                        value: '${value.qty}',
                        label: '${value.business.type.unitWord} terjual',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.s16),
              _BreakEvenCard(data: value),
              if (value.showCostBanner) ...<Widget>[
                const SizedBox(height: AppSpace.s16),
                SectionCard(
                  onTap: () => context.push('/profil/biaya'),
                  child: Row(
                    children: <Widget>[
                      Icon(LucideIcons.wallet, size: 20, color: colors.text),
                      const SizedBox(width: AppSpace.s12),
                      Expanded(
                        child: Text(
                          'Isi biaya operasional bulan ini supaya laba '
                          'bersihnya akurat.',
                          style: textTheme.bodyMedium,
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
              ],
              if (value.topMenus.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpace.s24),
                Text('Menu terlaris 30 hari', style: textTheme.titleLarge),
                const SizedBox(height: AppSpace.s12),
                SectionCard(
                  child: Column(
                    children: <Widget>[
                      for (var i = 0; i < value.topMenus.length; i++) ...[
                        if (i > 0)
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpace.s8,
                            ),
                            child: Divider(height: 1),
                          ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                value.topMenus[i].name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodyLarge,
                              ),
                            ),
                            Text(
                              '${value.topMenus[i].qty} '
                              '${value.business.type.unitWord}',
                              style: textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (!value.hasTodaySale) ...<Widget>[
                const SizedBox(height: AppSpace.s16),
                Text(
                  'Belum ada penjualan tercatat hari ini. Ketuk tombol + di '
                  'bawah untuk mencatat.',
                  style: textTheme.bodySmall,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _BreakEvenCard extends StatelessWidget {
  const _BreakEvenCard({required this.data});

  final BerandaData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final unitWord = data.business.type.unitWord;

    final (String title, String message, double? progress) =
        switch (data.breakEvenResult) {
          BreakEvenUnits(:final units) when units == 0 => (
            'Balik modal',
            data.costsFilled
                ? 'Biaya tetap harian nol, jadi semua laba kotor langsung '
                      'jadi laba bersih.'
                : 'Isi biaya operasional supaya titik balik modal bisa '
                      'dihitung.',
            null,
          ),
          BreakEvenUnits(:final units) => (
            'Balik modal hari ini: ${data.qty} dari $units $unitWord',
            data.qty >= units
                ? 'Sudah balik modal hari ini. Sisanya laba bersih.'
                : 'Kurang ${units - data.qty} $unitWord lagi untuk menutup '
                      'biaya tetap harian.',
            (data.qty / units).clamp(0, 1).toDouble(),
          ),
          BreakEvenNoData() => (
            'Balik modal',
            'Belum ada penjualan tercatat, jadi rata-rata laba per $unitWord '
                'belum bisa dihitung.',
            null,
          ),
          BreakEvenNoProfit() => (
            'Balik modal',
            'Rata-rata tiap $unitWord masih rugi, jadi menambah penjualan '
                'belum menutup biaya. Cek Analisis untuk menu yang menguras.',
            null,
          ),
        };

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: textTheme.titleLarge),
          const SizedBox(height: AppSpace.s8),
          if (progress != null) ...<Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpace.s4),
              child: LinearProgressIndicator(value: progress, minHeight: 8),
            ),
            const SizedBox(height: AppSpace.s8),
          ],
          Text(message, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
