import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:foodpilot/domain/models.dart';
import 'package:foodpilot/domain/monthly_report.dart';
import 'package:foodpilot/shared/format.dart';

/// Laporan bulanan PDF, berguna untuk pengajuan pinjaman (PRD F-12).
///
/// Font diambil dari aset aplikasi, jadi PDF tetap bisa dibuat tanpa
/// internet.
Future<Uint8List> buildMonthlyReportPdf({
  required Business business,
  required MonthlyReport report,
  required String monthLabel,
}) async {
  final regular = pw.Font.ttf(
    await rootBundle.load('assets/fonts/PlusJakartaSans-Regular.ttf'),
  );
  final bold = pw.Font.ttf(
    await rootBundle.load('assets/fonts/PlusJakartaSans-SemiBold.ttf'),
  );

  final document = pw.Document(
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );

  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => <pw.Widget>[
        pw.Text(business.name, style: const pw.TextStyle(fontSize: 22)),
        pw.SizedBox(height: 2),
        pw.Text('Laporan bulanan · $monthLabel'),
        pw.SizedBox(height: 16),
        pw.TableHelper.fromTextArray(
          headers: <String>['Ringkasan', 'Jumlah'],
          data: <List<String>>[
            <String>['Pendapatan', formatRupiah(report.revenue)],
            <String>['Laba kotor', formatRupiah(report.grossProfit)],
            <String>[
              'Biaya operasional',
              report.costsFilled
                  ? formatRupiah(report.operatingCost)
                  : 'belum diisi',
            ],
            <String>['Laba bersih', formatRupiah(report.netProfit)],
            <String>[
              '${business.type.unitWord} terjual',
              report.qty.toString(),
            ],
            <String>['Hari tercatat', report.days.length.toString()],
          ],
          cellAlignments: <int, pw.Alignment>{
            1: pw.Alignment.centerRight,
          },
        ),
        pw.SizedBox(height: 20),
        pw.Text('Per menu', style: const pw.TextStyle(fontSize: 14)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: <String>['Menu', 'Terjual', 'Pendapatan', 'Laba kotor'],
          data: <List<String>>[
            for (final menu in report.menus)
              <String>[
                menu.name,
                menu.qty.toString(),
                formatRupiah(menu.revenue),
                formatRupiah(menu.grossProfit),
              ],
          ],
          cellAlignments: <int, pw.Alignment>{
            1: pw.Alignment.centerRight,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
          },
        ),
        if (report.costs.isNotEmpty) ...<pw.Widget>[
          pw.SizedBox(height: 20),
          pw.Text('Biaya operasional', style: const pw.TextStyle(fontSize: 14)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: <String>['Biaya', 'Jumlah'],
            data: <List<String>>[
              for (final cost in report.costs)
                <String>[cost.name, formatRupiah(cost.amount)],
            ],
            cellAlignments: <int, pw.Alignment>{1: pw.Alignment.centerRight},
          ),
        ],
        pw.SizedBox(height: 20),
        pw.Text('Per hari', style: const pw.TextStyle(fontSize: 14)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: <String>['Tanggal', 'Terjual', 'Pendapatan', 'Laba kotor'],
          data: <List<String>>[
            for (final day in report.days)
              <String>[
                formatTanggal(day.date),
                day.qty.toString(),
                formatRupiah(day.revenue),
                formatRupiah(day.grossProfit),
              ],
          ],
          cellAlignments: <int, pw.Alignment>{
            1: pw.Alignment.centerRight,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
          },
        ),
        pw.SizedBox(height: 24),
        pw.Text(
          'Dibuat oleh aplikasi FoodPilot pada '
          '${formatTanggal(DateTime.now(), longMonth: true)}. Semua angka '
          'dihitung dari catatan penjualan di perangkat.',
          style: const pw.TextStyle(fontSize: 9),
        ),
      ],
    ),
  );

  return document.save();
}
