import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:foodpilot/app/theme/app_colors.dart';
import 'package:foodpilot/app/theme/brand.dart';
import 'package:foodpilot/app/theme/tokens.dart';
import 'package:foodpilot/domain/breakeven.dart';
import 'package:foodpilot/features/beranda/beranda_data.dart';
import 'package:foodpilot/shared/format.dart';
import 'package:foodpilot/shared/widgets/async_view.dart';
import 'package:foodpilot/shared/widgets/brand_card.dart';
import 'package:foodpilot/shared/widgets/empty_state.dart';
import 'package:foodpilot/shared/widgets/icon_box.dart';
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
    final data = ref.watch(berandaProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AsyncView<BerandaData?>(
          value: data,
          builder: (value) {
            if (value == null) {
              return const EmptyState(
                icon: LucideIcons.store,
                title: 'Belum ada data usaha',
                message: 'Isi data usaha dulu lewat onboarding.',
              );
            }
            return _Content(data: value);
          },
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.data});

  final BerandaData data;

    @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final brand = context.brand;
    final textTheme = Theme.of(context).textTheme;
    final net = data.net;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpace.s22,
        AppSpace.s16,
        AppSpace.s22,
        bottomChromeClearance(context),
      ),
      children: <Widget>[
        // Sapaan: tanggal kecil di atas, nama usaha serif di bawah.
        Text(formatTanggal(data.date), style: textTheme.bodySmall),
        const SizedBox(height: AppSpace.s4),
        Text(
          data.business.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppSerif.title.copyWith(color: colors.text),
        ),

        const SizedBox(height: AppSpace.s24),

        // Angka utama. Warnanya netral; tanda untung atau rugi dibawa oleh
        // chip kecil, supaya angka besar tidak berteriak.
        Row(
          children: <Widget>[
            Text('Laba bersih hari ini', style: textTheme.bodyMedium),
            const SizedBox(width: AppSpace.s8),
            if (net.isEstimate)
              StatusChip(
                label: 'estimasi',
                background: brand.surfaceMuted,
                foreground: colors.textMuted,
              )
            else if (net.value > 0)
              StatusChip(
                label: 'untung',
                background: brand.successTint,
                foreground: colors.success,
              )
            else if (net.value < 0)
              StatusChip(
                label: 'rugi',
                background: brand.dangerTint,
                foreground: colors.danger,
              ),
          ],
        ),
        const SizedBox(height: AppSpace.s4),
        Text(
          formatRupiah(net.value),
          style: AppSerif.hero.copyWith(
            color: net.value < 0 ? colors.danger : colors.text,
          ),
        ),
        const SizedBox(height: AppSpace.s8),
        Text(
          data.costsFilled
              ? 'Laba kotor dikurangi biaya tetap '
                    '${formatRupiah(data.dailyFixed)} per hari.'
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
                  value: formatRupiahCompact(data.revenue),
                  label: 'Pendapatan hari ini',
                ),
              ),
              const SizedBox(width: AppSpace.s8),
              Expanded(
                child: StatTile(
                  value: '${data.qty}',
                  label: '${data.business.type.unitWord} terjual',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpace.s16),
        _BreakEvenCard(data: data),

        if (data.showCostBanner) ...<Widget>[
          const SizedBox(height: AppSpace.s16),
          SectionCard(
            onTap: () => context.push('/profil/biaya'),
            child: Row(
              children: <Widget>[
                IconBox(
                  icon: LucideIcons.wallet,
                  background: brand.warningTint,
                  foreground: colors.warning,
                ),
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

        if (data.topMenus.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpace.s24),
          Text('Menu terlaris 30 hari', style: textTheme.titleLarge),
          const SizedBox(height: AppSpace.s12),
          SectionCard(
            child: Column(
              children: <Widget>[
                for (var i = 0; i < data.topMenus.length; i++) ...<Widget>[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpace.s8),
                      child: Divider(height: 1),
                    ),
                  Row(
                    children: <Widget>[
                      IconBox(
                        label: '${i + 1}',
                        background: brand.brandTint,
                        foreground: brand.brand,
                        size: 32,
                      ),
                      const SizedBox(width: AppSpace.s12),
                      Expanded(
                        child: Text(
                          data.topMenus[i].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyLarge,
                        ),
                      ),
                      Text(
                        '${data.topMenus[i].qty}',
                        style: AppSerif.number.copyWith(color: colors.text),
                      ),
                      const SizedBox(width: AppSpace.s4),
                      Text(
                        data.business.type.unitWord,
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],

        if (!data.hasTodaySale) ...<Widget>[
          const SizedBox(height: AppSpace.s16),
          Text(
            'Belum ada penjualan tercatat hari ini. Ketuk tombol + di '
            'bawah untuk mencatat.',
            style: textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _BreakEvenCard extends StatelessWidget {
  const _BreakEvenCard({required this.data});

  final BerandaData data;

    @override
  Widget build(BuildContext context) {
    final brand = context.brand;
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
            'Balik modal hari ini',
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

    // Kartu merek hanya dipakai saat ada progress nyata. Untuk kondisi
    // kosong atau rugi, bidang warna besar justru terasa berteriak.
    if (progress == null) {
      return SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: textTheme.titleLarge),
            const SizedBox(height: AppSpace.s8),
            Text(message, style: textTheme.bodyMedium),
          ],
        ),
      );
    }

    final units = switch (data.breakEvenResult) {
      BreakEvenUnits(:final units) => units,
      _ => 0,
    };

    return BrandCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: textTheme.bodyMedium?.copyWith(
              color: brand.onBrand.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: AppSpace.s4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                '${data.qty}',
                style: AppSerif.hero.copyWith(
                  fontSize: 36,
                  color: brand.onBrand,
                ),
              ),
              const SizedBox(width: AppSpace.s8),
              Text(
                'dari $units $unitWord',
                style: textTheme.bodyMedium?.copyWith(
                  color: brand.onBrand.withValues(alpha: 0.82),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpace.s4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: brand.onBrand.withValues(alpha: 0.24),
              valueColor: AlwaysStoppedAnimation<Color>(brand.onBrand),
            ),
          ),
          const SizedBox(height: AppSpace.s12),
          Text(
            message,
            style: textTheme.bodySmall?.copyWith(
              color: brand.onBrand.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }
}