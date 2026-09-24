import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:printing/printing.dart';

import 'package:foodpilot/app/theme/app_colors.dart';
import 'package:foodpilot/app/theme/tokens.dart';
import 'package:foodpilot/data/providers.dart';
import 'package:foodpilot/domain/models.dart';
import 'package:foodpilot/domain/monthly_report.dart';
import 'package:foodpilot/features/profil/laporan_pdf.dart';
import 'package:foodpilot/shared/dates.dart';
import 'package:foodpilot/shared/format.dart';
import 'package:foodpilot/shared/widgets/action_pill.dart';
import 'package:foodpilot/shared/widgets/app_snack.dart';
import 'package:foodpilot/shared/widgets/section_card.dart';

class LaporanScreen extends ConsumerStatefulWidget {
  const LaporanScreen({super.key});

  @override
  ConsumerState<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends ConsumerState<LaporanScreen> {
  late String _period = periodKey(today());
  bool _sharing = false;

  Future<void> _share(Business business, MonthlyReport report) async {
    setState(() => _sharing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await buildMonthlyReportPdf(
        business: business,
        report: report,
        monthLabel: formatBulan(periodStart(_period)),
      );
      await Printing.sharePdf(bytes: bytes, filename: 'foodpilot-$_period.pdf');
    } catch (error) {
      showSnackOn(messenger, 'Gagal membuat PDF: $error');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final business = ref.watch(businessProvider).value;
    final sales = ref.watch(recentSalesProvider).value ?? const <DaySale>[];
    final costs = ref.watch(costsProvider(_period)).value ?? const <CostItem>[];

    final report = buildMonthlyReport(
      period: _period,
      sales: sales,
      costs: costs,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan bulanan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s22,
          AppSpace.s8,
          AppSpace.s22,
          AppSpace.s24,
        ),
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                onPressed: () =>
                    setState(() => _period = previousPeriod(_period)),
                icon: const Icon(LucideIcons.chevronLeft),
                tooltip: 'Bulan sebelumnya',
              ),
              Expanded(
                child: Text(
                  formatBulan(periodStart(_period)),
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _period = nextPeriod(_period)),
                icon: const Icon(LucideIcons.chevronRight),
                tooltip: 'Bulan berikutnya',
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s8),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _ReportLine(
                  label: 'Pendapatan',
                  value: formatRupiah(report.revenue),
                ),
                _ReportLine(
                  label: 'Laba kotor',
                  value: formatRupiah(report.grossProfit),
                ),
                _ReportLine(
                  label: 'Biaya operasional',
                  value: report.costsFilled
                      ? formatRupiah(report.operatingCost)
                      : 'belum diisi',
                ),
                const Divider(),
                _ReportLine(
                  label: 'Laba bersih',
                  value: formatRupiah(report.netProfit),
                  color: report.netProfit >= 0 ? colors.success : colors.danger,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s16),
          Text(
            '${report.days.length} hari tercatat · ${report.qty} '
            '${business?.type.unitWord ?? 'porsi'} terjual',
            style: textTheme.bodySmall,
          ),
          if (report.menus.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpace.s16),
            SectionCard(
              child: Column(
                children: <Widget>[
                  for (final menu in report.menus.take(5))
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpace.s4,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              menu.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyLarge,
                            ),
                          ),
                          Text(
                            formatRupiah(menu.grossProfit),
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: ActionPill(
        label: _sharing ? 'Menyiapkan PDF…' : 'Bagikan PDF',
        onPressed: business == null || _sharing
            ? null
            : () => unawaited(_share(business, report)),
      ),
    );
  }
}

class _ReportLine extends StatelessWidget {
  const _ReportLine({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s4),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: textTheme.bodyMedium)),
          Text(value, style: textTheme.titleLarge?.copyWith(color: color)),
        ],
      ),
    );
  }
}
