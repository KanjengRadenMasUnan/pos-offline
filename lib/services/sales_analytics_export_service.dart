import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as xl;
import 'package:archive/archive.dart';

import '../models/sales_analytics_model.dart';
import '../services/sales_insight_engine.dart';
import '../services/sales_chart_image_renderer.dart';
import '../utils/currency_format.dart';

class SalesAnalyticsExportService {
  static final SalesAnalyticsExportService instance =
      SalesAnalyticsExportService._();
  SalesAnalyticsExportService._();

  String _formatSafeDate(DateTime dt, [String pattern = 'dd MMMM yyyy HH:mm']) {
    try {
      return DateFormat(pattern, 'id_ID').format(dt);
    } catch (_) {
      return DateFormat('dd-MM-yyyy HH:mm').format(dt);
    }
  }

  // =========================================================================
  // 1. EXPORT TO PDF (.pdf) - DENGAN DIAGRAM BATANG & GARIS
  // =========================================================================
  Future<File> exportToPdf(SalesAnalyticsSummary summary) async {
    final pdf = pw.Document();
    final insights = summary.insights ??
        SalesInsightEngine.generateInsights(summary: summary);
    final printDate = _formatSafeDate(DateTime.now());

    // Generate gambar grafik resolusi tajam
    final barChartBytes = SalesChartImageRenderer.renderBarChart(summary, width: 800, height: 350);
    final lineChartBytes = SalesChartImageRenderer.renderLineChart(summary, width: 800, height: 350);

    // HALAMAN 1: Cover Eksekutif, KPI & Dua Diagram Grafik Visual
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // HEADER RESMI
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 10),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue900, width: 2)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'NANDA CELL - LAPORAN ANALITIK PENJUALAN',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Periode: ${summary.periodTitle}',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Cetak: $printDate',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // 4 KARTU METRIK KPI
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildPdfKpiBox(
                    'TOTAL OMSET',
                    CurrencyFormat.convertToIdr(summary.totalRevenue, 0),
                    PdfColors.green800,
                    PdfColors.green50,
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Expanded(
                  child: _buildPdfKpiBox(
                    'TRANSAKSI',
                    '${NumberFormat('#,###').format(summary.totalTransactions)}x',
                    PdfColors.blue800,
                    PdfColors.blue50,
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Expanded(
                  child: _buildPdfKpiBox(
                    'RATA-RATA/TITIK',
                    CurrencyFormat.convertToIdr(summary.averageRevenue, 0),
                    PdfColors.purple800,
                    PdfColors.purple50,
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Expanded(
                  child: _buildPdfKpiBox(
                    'NILAI BELANJA (AOV)',
                    CurrencyFormat.convertToIdr(insights.averageOrderValue, 0),
                    PdfColors.orange800,
                    PdfColors.orange50,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),

            // KOTAK INSIGHT RINGKAS
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'RANGKUMAN EKSEKUTIF: ${insights.trendStatus.toUpperCase()} (Stabilitas: ${insights.stabilityLevel})',
                          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          insights.executiveSummary,
                          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey900, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // 1. VISUALISASI DIAGRAM BATANG
            pw.Text(
              '1. Visualisasi Diagram Batang (Omset per Periode)',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              height: 195,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.ClipRRect(
                horizontalRadius: 6,
                verticalRadius: 6,
                child: pw.Image(pw.MemoryImage(barChartBytes), fit: pw.BoxFit.contain),
              ),
            ),
            pw.SizedBox(height: 10),

            // 2. VISUALISASI DIAGRAM GARIS
            pw.Text(
              '2. Visualisasi Diagram Garis (Tren Fluktuasi & Momentum)',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              height: 195,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.ClipRRect(
                horizontalRadius: 6,
                verticalRadius: 6,
                child: pw.Image(pw.MemoryImage(lineChartBytes), fit: pw.BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );

    // HALAMAN 2: Tabel Rincian Data Lengkap & Top Produk
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Header Mini Halaman 2
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 8),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 1)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'RINCIAN DATA ANGKA PENJUALAN - ${summary.periodTitle}',
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                  ),
                  pw.Text('Halaman 2', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // TABEL RINCIAN TITIK WAKTU
            pw.TableHelper.fromTextArray(
              headers: ['No', 'Periode', 'Jumlah Transaksi', 'Total Omset (Rp)', 'Kontribusi (%)'],
              data: List.generate(summary.dataPoints.length, (i) {
                final p = summary.dataPoints[i];
                final share = summary.totalRevenue > 0
                    ? (p.totalAmount / summary.totalRevenue * 100).toStringAsFixed(1)
                    : '0.0';
                return [
                  '${i + 1}',
                  p.fullLabel,
                  '${p.transactionCount}x',
                  CurrencyFormat.convertToIdr(p.totalAmount, 0),
                  '$share%',
                ];
              }),
              headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                0: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
              },
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
              ),
            ),
            pw.SizedBox(height: 16),

            // TABEL TOP PRODUK
            if (summary.topProducts.isNotEmpty) ...[
              pw.Text(
                'Top Produk Terlaris pada Periode Ini',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
              ),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: ['Peringkat', 'Nama Produk', 'Jumlah Terjual (Qty)'],
                data: List.generate(summary.topProducts.take(8).length, (i) {
                  final item = summary.topProducts[i];
                  return [
                    '#${i + 1}',
                    item['product_name'] ?? '-',
                    '${item['total_qty'] ?? 0} pcs',
                  ];
                }),
                headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerRight,
                },
              ),
            ],
            pw.Spacer(),

            // FOOTER & LEMBAR PENGESAHAN
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Catatan: Laporan dihasilkan secara otomatis dari sistem POS Nanda Cell.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    pw.Text('Integritas data diverifikasi berdasarkan catatan transaksi offline.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('Penanggung Jawab Toko,', style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 35),
                    pw.Text('( ........................................ )', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/ANALISIS_NANDACELL_$timestamp.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildPdfKpiBox(
    String label,
    String value,
    PdfColor textColor,
    PdfColor bgColor,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: textColor, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
          pw.SizedBox(height: 2),
          pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  // =========================================================================
  // 2. EXPORT TO EXCEL (.xlsx) - BUKU KERJA FINANSIAL DENGAN DIAGRAM BATANG & GARIS
  // =========================================================================
  Future<File> exportToExcel(SalesAnalyticsSummary summary) async {
    final excel = xl.Excel.createExcel();
    final insights = summary.insights ??
        SalesInsightEngine.generateInsights(summary: summary);

    final points = summary.dataPoints;
    double maxAmt = 0;
    for (var p in points) {
      if (p.totalAmount > maxAmt) maxAmt = p.totalAmount.toDouble();
    }
    if (maxAmt == 0) maxAmt = 1;

    // Header styling
    final headerNavy = xl.CellStyle(
      bold: true,
      backgroundColorHex: xl.ExcelColor.fromHexString('#0F172A'),
      fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
    );
    final headerBlue = xl.CellStyle(
      bold: true,
      backgroundColorHex: xl.ExcelColor.fromHexString('#2563EB'),
      fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
    );
    final headerTeal = xl.CellStyle(
      bold: true,
      backgroundColorHex: xl.ExcelColor.fromHexString('#0D9488'),
      fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
    );

    // SHEET 1: Ringkasan Eksekutif & KPI
    const sheet1Name = 'Ringkasan & KPI';
    final sheet1 = excel[sheet1Name];
    excel.delete('Sheet1');

    sheet1.appendRow([xl.TextCellValue('NANDA CELL - LAPORAN ANALITIK PENJUALAN')]);
    sheet1.cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle =
        xl.CellStyle(bold: true, fontSize: 13);
    sheet1.appendRow([xl.TextCellValue('Periode: ${summary.periodTitle}')]);
    sheet1.appendRow([xl.TextCellValue('Tanggal Ekspor: ${_formatSafeDate(DateTime.now())}')]);
    sheet1.appendRow([xl.TextCellValue('')]);

    // METRIK UTAMA
    sheet1.appendRow([xl.TextCellValue('INDIKATOR KINERJA UTAMA (KPI)'), xl.TextCellValue('NILAI ANALISIS')]);
    sheet1.cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4)).cellStyle = headerNavy;
    sheet1.cell(xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4)).cellStyle = headerNavy;

    sheet1.appendRow([xl.TextCellValue('Total Omset Penjualan'), xl.TextCellValue(CurrencyFormat.convertToIdr(summary.totalRevenue, 0))]);
    sheet1.appendRow([xl.TextCellValue('Total Transaksi Struk'), xl.IntCellValue(summary.totalTransactions)]);
    sheet1.appendRow([xl.TextCellValue('Rata-rata Omset per Periode'), xl.TextCellValue(CurrencyFormat.convertToIdr(summary.averageRevenue, 0))]);
    sheet1.appendRow([xl.TextCellValue('Rata-rata Belanja per Struk (AOV)'), xl.TextCellValue(CurrencyFormat.convertToIdr(insights.averageOrderValue, 0))]);
    sheet1.appendRow([xl.TextCellValue('Status Tren Penjualan'), xl.TextCellValue(insights.trendStatus)]);
    sheet1.appendRow([xl.TextCellValue('Stabilitas Arus Kas'), xl.TextCellValue(insights.stabilityLevel)]);
    if (insights.peakPoint != null) {
      sheet1.appendRow([
        xl.TextCellValue('Puncak Omset Tertinggi'),
        xl.TextCellValue('${insights.peakPoint!.label} (${CurrencyFormat.convertToIdr(insights.peakPoint!.totalAmount, 0)})'),
      ]);
    }
    sheet1.appendRow([xl.TextCellValue('')]);

    // RANGKUMAN EKSEKUTIF
    sheet1.appendRow([xl.TextCellValue('RANGKUMAN EKSEKUTIF')]);
    sheet1.cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: sheet1.maxRows - 1)).cellStyle = headerBlue;
    sheet1.appendRow([xl.TextCellValue(insights.executiveSummary)]);
    sheet1.appendRow([xl.TextCellValue('')]);

    // TOP PRODUK
    if (summary.topProducts.isNotEmpty) {
      sheet1.appendRow([
        xl.TextCellValue('PERINGKAT'),
        xl.TextCellValue('PRODUK TERLARIS'),
        xl.TextCellValue('QTY TERJUAL'),
      ]);
      final topHeaderRow = sheet1.maxRows - 1;
      for (int c = 0; c < 3; c++) {
        sheet1.cell(xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: topHeaderRow)).cellStyle = headerNavy;
      }
      for (int i = 0; i < summary.topProducts.length; i++) {
        final it = summary.topProducts[i];
        sheet1.appendRow([
          xl.TextCellValue('#${i + 1}'),
          xl.TextCellValue(it['product_name'] ?? '-'),
          xl.IntCellValue(it['total_qty'] ?? 0),
        ]);
      }
    }

    // SHEET 2: Diagram Batang (Visual Data Bars)
    const sheet2Name = 'Diagram Batang';
    final sheet2 = excel[sheet2Name];
    sheet2.appendRow([
      xl.TextCellValue('No'),
      xl.TextCellValue('Periode Waktu'),
      xl.TextCellValue('Transaksi'),
      xl.TextCellValue('Total Omset (Rp)'),
      xl.TextCellValue('DIAGRAM BATANG PENJUALAN (VISUALISASI DATA BAR)'),
      xl.TextCellValue('Kontribusi (%)'),
    ]);
    for (int col = 0; col < 6; col++) {
      sheet2.cell(xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0)).cellStyle = headerBlue;
    }

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final ratio = p.totalAmount / maxAmt;
      final barLength = (ratio * 30).round();
      final barVisual = '█' * barLength;
      final share = summary.totalRevenue > 0
          ? (p.totalAmount / summary.totalRevenue * 100)
          : 0.0;

      sheet2.appendRow([
        xl.IntCellValue(i + 1),
        xl.TextCellValue(p.fullLabel),
        xl.IntCellValue(p.transactionCount),
        xl.IntCellValue(p.totalAmount),
        xl.TextCellValue('$barVisual (${(ratio * 100).toStringAsFixed(0)}%)'),
        xl.DoubleCellValue(double.parse(share.toStringAsFixed(1))),
      ]);
    }

    // SHEET 3: Diagram Garis (Visual Tren Momentum)
    const sheet3Name = 'Diagram Garis';
    final sheet3 = excel[sheet3Name];
    sheet3.appendRow([
      xl.TextCellValue('No'),
      xl.TextCellValue('Periode Waktu'),
      xl.TextCellValue('Total Omset (Rp)'),
      xl.TextCellValue('DIAGRAM GARIS TREN PENJUALAN'),
      xl.TextCellValue('Arah Momentum'),
      xl.TextCellValue('Perubahan Omset (+/-)'),
    ]);
    for (int col = 0; col < 6; col++) {
      sheet3.cell(xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0)).cellStyle = headerTeal;
    }

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      String trendLineSymbol;
      String direction;
      String diffText = '-';

      if (i == 0) {
        trendLineSymbol = '● ──────────────────';
        direction = '[TITIK AWAL]';
      } else {
        final prev = points[i - 1].totalAmount;
        final diff = p.totalAmount - prev;
        final pct = prev > 0 ? (diff / prev * 100) : 100.0;
        diffText = CurrencyFormat.convertToIdr(diff, 0);

        if (diff > 0) {
          direction = '▲ NAIK (+${pct.toStringAsFixed(1)}%)';
          trendLineSymbol = '─────── ▲ ──────────';
        } else if (diff < 0) {
          direction = '▼ TURUN (${pct.toStringAsFixed(1)}%)';
          trendLineSymbol = '───────────── ▼ ────';
        } else {
          direction = '― STABIL (0.0%)';
          trendLineSymbol = '────────────────────';
        }
      }

      sheet3.appendRow([
        xl.IntCellValue(i + 1),
        xl.TextCellValue(p.fullLabel),
        xl.IntCellValue(p.totalAmount),
        xl.TextCellValue(trendLineSymbol),
        xl.TextCellValue(direction),
        xl.TextCellValue(diffText),
      ]);
    }

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/ANALISIS_NANDACELL_$timestamp.xlsx');
    final bytes = excel.save();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }
    return file;
  }

  // =========================================================================
  // 3. EXPORT TO POWERPOINT (.pptx) - SLIDE DEK PRESENTASI 16:9 DENGAN 2 SLIDE GRAFIK KHUSUS
  // =========================================================================
  Future<File> exportToPptx(SalesAnalyticsSummary summary) async {
    final insights = summary.insights ??
        SalesInsightEngine.generateInsights(summary: summary);
    final printDate = _formatSafeDate(DateTime.now(), 'dd MMMM yyyy');

    // Generate gambar grafik untuk slide diagram batang & garis
    final barChartBytes = SalesChartImageRenderer.renderBarChart(summary, width: 960, height: 480);
    final lineChartBytes = SalesChartImageRenderer.renderLineChart(summary, width: 960, height: 480);

    final archive = Archive();

    String xmlEscape(String text) {
      return text
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;')
          .replaceAll('"', '&quot;')
          .replaceAll("'", '&apos;');
    }

    // 1. [Content_Types].xml (5 Slides + PNG media)
    const contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Default Extension="png" ContentType="image/png"/>
  <Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>
  <Override PartName="/ppt/slideMasters/slideMaster1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml"/>
  <Override PartName="/ppt/slideLayouts/slideLayout1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"/>
  <Override PartName="/ppt/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>
  <Override PartName="/ppt/slides/slide1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>
  <Override PartName="/ppt/slides/slide2.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>
  <Override PartName="/ppt/slides/slide3.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>
  <Override PartName="/ppt/slides/slide4.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>
  <Override PartName="/ppt/slides/slide5.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>
</Types>''';
    archive.addFile(ArchiveFile('[Content_Types].xml', contentTypesXml.length, contentTypesXml.codeUnits));

    // 2. _rels/.rels
    const rootRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>
</Relationships>''';
    archive.addFile(ArchiveFile('_rels/.rels', rootRelsXml.length, rootRelsXml.codeUnits));

    // 3. ppt/presentation.xml (5 Slides 16:9 Widescreen)
    const presentationXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:presentation xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:sldMasterIdLst><p:sldMasterId id="2147483648" r:id="rId1"/></p:sldMasterIdLst>
  <p:sldIdLst>
    <p:sldId id="256" r:id="rId2"/>
    <p:sldId id="257" r:id="rId3"/>
    <p:sldId id="258" r:id="rId4"/>
    <p:sldId id="259" r:id="rId5"/>
    <p:sldId id="260" r:id="rId6"/>
  </p:sldIdLst>
  <p:sldSz cx="12192000" cy="6858000" type="screen16x9"/>
  <p:notesSz cx="6858000" cy="9144000"/>
</p:presentation>''';
    archive.addFile(ArchiveFile('ppt/presentation.xml', presentationXml.length, presentationXml.codeUnits));

    // 4. ppt/_rels/presentation.xml.rels
    const presentationRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="slideMasters/slideMaster1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide1.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide2.xml"/>
  <Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide3.xml"/>
  <Relationship Id="rId5" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide4.xml"/>
  <Relationship Id="rId6" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide5.xml"/>
</Relationships>''';
    archive.addFile(ArchiveFile('ppt/_rels/presentation.xml.rels', presentationRelsXml.length, presentationRelsXml.codeUnits));

    // 5. ppt/slideMasters/slideMaster1.xml
    const slideMasterXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sldMaster xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:cSld>
    <p:spTree>
      <p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>
      <p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>
    </p:spTree>
  </p:cSld>
  <p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" accent1="accent1" accent2="accent2" accent3="accent3" accent4="accent4" accent5="accent5" accent6="accent6" hlink="hlink" folHlink="folHlink"/>
  <p:sldLayoutIdLst><p:sldLayoutId id="2147483649" r:id="rId1"/></p:sldLayoutIdLst>
</p:sldMaster>''';
    archive.addFile(ArchiveFile('ppt/slideMasters/slideMaster1.xml', slideMasterXml.length, slideMasterXml.codeUnits));

    // 6. ppt/slideMasters/_rels/slideMaster1.xml.rels
    const slideMasterRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="../theme/theme1.xml"/>
</Relationships>''';
    archive.addFile(ArchiveFile('ppt/slideMasters/_rels/slideMaster1.xml.rels', slideMasterRelsXml.length, slideMasterRelsXml.codeUnits));

    // 7. ppt/slideLayouts/slideLayout1.xml
    const slideLayoutXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sldLayout xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" type="blank">
  <p:cSld>
    <p:spTree>
      <p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>
      <p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>
    </p:spTree>
  </p:cSld>
  <p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>
</p:sldLayout>''';
    archive.addFile(ArchiveFile('ppt/slideLayouts/slideLayout1.xml', slideLayoutXml.length, slideLayoutXml.codeUnits));

    // 8. ppt/slideLayouts/_rels/slideLayout1.xml.rels
    const slideLayoutRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="../slideMasters/slideMaster1.xml"/>
</Relationships>''';
    archive.addFile(ArchiveFile('ppt/slideLayouts/_rels/slideLayout1.xml.rels', slideLayoutRelsXml.length, slideLayoutRelsXml.codeUnits));

    // 9. ppt/theme/theme1.xml
    const themeXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="Office Theme">
  <a:themeElements>
    <a:clrScheme name="Office">
      <a:dk1><a:srgbClr val="0F172A"/></a:dk1>
      <a:lt1><a:srgbClr val="FFFFFF"/></a:lt1>
      <a:dk2><a:srgbClr val="1E293B"/></a:dk2>
      <a:lt2><a:srgbClr val="F8FAFC"/></a:lt2>
      <a:accent1><a:srgbClr val="2563EB"/></a:accent1>
      <a:accent2><a:srgbClr val="10B981"/></a:accent2>
      <a:accent3><a:srgbClr val="F59E0B"/></a:accent3>
      <a:accent4><a:srgbClr val="EF4444"/></a:accent4>
      <a:accent5><a:srgbClr val="6366F1"/></a:accent5>
      <a:accent6><a:srgbClr val="0D9488"/></a:accent6>
      <a:hlink><a:srgbClr val="2563EB"/></a:hlink>
      <a:folHlink><a:srgbClr val="7C3AED"/></a:folHlink>
    </a:clrScheme>
    <a:fontScheme name="Office">
      <a:majorFont><a:latin typeface="Arial"/></a:majorFont>
      <a:minorFont><a:latin typeface="Arial"/></a:minorFont>
    </a:fontScheme>
    <a:fmtScheme name="Office">
      <a:fillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:fillStyleLst>
      <a:lnStyleLst><a:ln w="9525"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln></a:lnStyleLst>
      <a:effectStyleLst><a:effectStyle><a:effectLst/></a:effectStyle></a:effectStyleLst>
      <a:bgFillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:bgFillStyleLst>
    </a:fmtScheme>
  </a:themeElements>
</a:theme>''';
    archive.addFile(ArchiveFile('ppt/theme/theme1.xml', themeXml.length, themeXml.codeUnits));

    // Media files (gambar chart)
    archive.addFile(ArchiveFile('ppt/media/image1.png', barChartBytes.length, barChartBytes));
    archive.addFile(ArchiveFile('ppt/media/image2.png', lineChartBytes.length, lineChartBytes));

    // Slide rels
    const defaultSlideRelXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
</Relationships>''';

    const slide3RelXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="../media/image1.png"/>
</Relationships>''';

    const slide4RelXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="../media/image2.png"/>
</Relationships>''';

    archive.addFile(ArchiveFile('ppt/slides/_rels/slide1.xml.rels', defaultSlideRelXml.length, defaultSlideRelXml.codeUnits));
    archive.addFile(ArchiveFile('ppt/slides/_rels/slide2.xml.rels', defaultSlideRelXml.length, defaultSlideRelXml.codeUnits));
    archive.addFile(ArchiveFile('ppt/slides/_rels/slide3.xml.rels', slide3RelXml.length, slide3RelXml.codeUnits));
    archive.addFile(ArchiveFile('ppt/slides/_rels/slide4.xml.rels', slide4RelXml.length, slide4RelXml.codeUnits));
    archive.addFile(ArchiveFile('ppt/slides/_rels/slide5.xml.rels', defaultSlideRelXml.length, defaultSlideRelXml.codeUnits));

    // SLIDE 1: Cover Judul Elegan
    final slide1Xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:cSld>
    <p:spTree>
      <p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>
      <p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>
      <p:sp>
        <p:nvSpPr><p:cNvPr id="2" name="CoverBox"/><p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr><p:nvPr/></p:nvSpPr>
        <p:spPr>
          <a:xfrm><a:off x="1000000" y="1200000"/><a:ext cx="10192000" cy="4458000"/></a:xfrm>
          <a:prstGeom prst="roundRect"><a:avLst><a:gd name="adj" fmla="val 2000"/></a:avLst></a:prstGeom>
          <a:solidFill><a:srgbClr val="0F172A"/></a:solidFill>
          <a:ln w="25400"><a:solidFill><a:srgbClr val="2563EB"/></a:solidFill></a:ln>
        </p:spPr>
        <p:txBody>
          <a:bodyPr vert="horz" lIns="400000" tIns="400000" rIns="400000" bIns="400000" anchor="ctr"/>
          <a:lstStyle/>
          <a:p>
            <a:pPr algn="ctr"/>
            <a:r>
              <a:rPr lang="id-ID" sz="1600" b="1"><a:solidFill><a:srgbClr val="38BDF8"/></a:solidFill></a:rPr>
              <a:t>NANDA CELL POS • EXECUTIVE REPORT</a:t>
            </a:r>
          </a:p>
          <a:p>
            <a:pPr algn="ctr"/>
            <a:r>
              <a:rPr lang="id-ID" sz="3600" b="1"><a:solidFill><a:srgbClr val="FFFFFF"/></a:solidFill></a:rPr>
              <a:t>LAPORAN ANALITIK PENJUALAN</a:t>
            </a:r>
          </a:p>
          <a:p>
            <a:pPr algn="ctr"/>
            <a:r>
              <a:rPr lang="id-ID" sz="2200"><a:solidFill><a:srgbClr val="94A3B8"/></a:solidFill></a:rPr>
              <a:t>${xmlEscape(summary.periodTitle)}</a:t>
            </a:r>
          </a:p>
          <a:p>
            <a:pPr algn="ctr"/>
            <a:r>
              <a:rPr lang="id-ID" sz="1300"><a:solidFill><a:srgbClr val="64748B"/></a:solidFill></a:rPr>
              <a:t>Tanggal Ekspor: $printDate</a:t>
            </a:r>
          </a:p>
        </p:txBody>
      </p:sp>
    </p:spTree>
  </p:cSld>
  <p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>
</p:sld>''';
    archive.addFile(ArchiveFile('ppt/slides/slide1.xml', slide1Xml.length, slide1Xml.codeUnits));

    // SLIDE 2: Ringkasan Metrik KPI & Rangkuman Eksekutif
    final slide2Xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:cSld>
    <p:spTree>
      <p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>
      <p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>
      <p:sp>
        <p:nvSpPr><p:cNvPr id="2" name="Title"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr>
        <p:spPr><a:xfrm><a:off x="800000" y="500000"/><a:ext cx="10592000" cy="600000"/></a:xfrm></p:spPr>
        <p:txBody>
          <a:bodyPr/><a:lstStyle/>
          <a:p>
            <a:r><a:rPr sz="2400" b="1"><a:solidFill><a:srgbClr val="0F172A"/></a:solidFill></a:rPr>
            <a:t>RINGKASAN EKSEKUTIF &amp; METRIK UTAMA</a:t></a:r>
          </a:p>
        </p:txBody>
      </p:sp>

      <!-- Box 1: Total Omset -->
      <p:sp>
        <p:nvSpPr><p:cNvPr id="3" name="KPI1"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr>
        <p:spPr>
          <a:xfrm><a:off x="800000" y="1300000"/><a:ext cx="2500000" cy="1100000"/></a:xfrm>
          <a:prstGeom prst="roundRect"><a:avLst><a:gd name="adj" fmla="val 2000"/></a:avLst></a:prstGeom>
          <a:solidFill><a:srgbClr val="ECFDF5"/></a:solidFill>
          <a:ln w="12700"><a:solidFill><a:srgbClr val="059669"/></a:solidFill></a:ln>
        </p:spPr>
        <p:txBody>
          <a:bodyPr lIns="150000" tIns="150000" rIns="150000" bIns="150000"/>
          <a:lstStyle/>
          <a:p><a:r><a:rPr sz="1100"><a:solidFill><a:srgbClr val="047857"/></a:solidFill></a:rPr><a:t>TOTAL OMSET</a:t></a:r></a:p>
          <a:p><a:r><a:rPr sz="1600" b="1"><a:solidFill><a:srgbClr val="065F46"/></a:solidFill></a:rPr><a:t>${xmlEscape(CurrencyFormat.convertToIdr(summary.totalRevenue, 0))}</a:t></a:r></a:p>
        </p:txBody>
      </p:sp>

      <!-- Box 2: Total Transaksi -->
      <p:sp>
        <p:nvSpPr><p:cNvPr id="4" name="KPI2"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr>
        <p:spPr>
          <a:xfrm><a:off x="3500000" y="1300000"/><a:ext cx="2500000" cy="1100000"/></a:xfrm>
          <a:prstGeom prst="roundRect"><a:avLst><a:gd name="adj" fmla="val 2000"/></a:avLst></a:prstGeom>
          <a:solidFill><a:srgbClr val="EFF6FF"/></a:solidFill>
          <a:ln w="12700"><a:solidFill><a:srgbClr val="2563EB"/></a:solidFill></a:ln>
        </p:spPr>
        <p:txBody>
          <a:bodyPr lIns="150000" tIns="150000" rIns="150000" bIns="150000"/>
          <a:lstStyle/>
          <a:p><a:r><a:rPr sz="1100"><a:solidFill><a:srgbClr val="1D4ED8"/></a:solidFill></a:rPr><a:t>TOTAL TRANSAKSI</a:t></a:r></a:p>
          <a:p><a:r><a:rPr sz="1600" b="1"><a:solidFill><a:srgbClr val="1E40AF"/></a:solidFill></a:rPr><a:t>${NumberFormat('#,###').format(summary.totalTransactions)} Transaksi</a:t></a:r></a:p>
        </p:txBody>
      </p:sp>

      <!-- Box 3: Rata-rata/Titik -->
      <p:sp>
        <p:nvSpPr><p:cNvPr id="5" name="KPI3"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr>
        <p:spPr>
          <a:xfrm><a:off x="6200000" y="1300000"/><a:ext cx="2500000" cy="1100000"/></a:xfrm>
          <a:prstGeom prst="roundRect"><a:avLst><a:gd name="adj" fmla="val 2000"/></a:avLst></a:prstGeom>
          <a:solidFill><a:srgbClr val="F5F3FF"/></a:solidFill>
          <a:ln w="12700"><a:solidFill><a:srgbClr val="7C3AED"/></a:solidFill></a:ln>
        </p:spPr>
        <p:txBody>
          <a:bodyPr lIns="150000" tIns="150000" rIns="150000" bIns="150000"/>
          <a:lstStyle/>
          <a:p><a:r><a:rPr sz="1100"><a:solidFill><a:srgbClr val="6D28D9"/></a:solidFill></a:rPr><a:t>RATA-RATA / PERIODE</a:t></a:r></a:p>
          <a:p><a:r><a:rPr sz="1600" b="1"><a:solidFill><a:srgbClr val="5B21B6"/></a:solidFill></a:rPr><a:t>${xmlEscape(CurrencyFormat.convertToIdr(summary.averageRevenue, 0))}</a:t></a:r></a:p>
        </p:txBody>
      </p:sp>

      <!-- Box 4: AOV -->
      <p:sp>
        <p:nvSpPr><p:cNvPr id="6" name="KPI4"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr>
        <p:spPr>
          <a:xfrm><a:off x="8900000" y="1300000"/><a:ext cx="2500000" cy="1100000"/></a:xfrm>
          <a:prstGeom prst="roundRect"><a:avLst><a:gd name="adj" fmla="val 2000"/></a:avLst></a:prstGeom>
          <a:solidFill><a:srgbClr val="FFFBEB"/></a:solidFill>
          <a:ln w="12700"><a:solidFill><a:srgbClr val="D97706"/></a:solidFill></a:ln>
        </p:spPr>
        <p:txBody>
          <a:bodyPr lIns="150000" tIns="150000" rIns="150000" bIns="150000"/>
          <a:lstStyle/>
          <a:p><a:r><a:rPr sz="1100"><a:solidFill><a:srgbClr val="B45309"/></a:solidFill></a:rPr><a:t>RATA-RATA BELANJA (AOV)</a:t></a:r></a:p>
          <a:p><a:r><a:rPr sz="1600" b="1"><a:solidFill><a:srgbClr val="92400E"/></a:solidFill></a:rPr><a:t>${xmlEscape(CurrencyFormat.convertToIdr(insights.averageOrderValue, 0))}</a:t></a:r></a:p>
        </p:txBody>
      </p:sp>

      <!-- Box Insight -->
      <p:sp>
        <p:nvSpPr><p:cNvPr id="7" name="InsightBox"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr>
        <p:spPr>
          <a:xfrm><a:off x="800000" y="2600000"/><a:ext cx="10600000" cy="3600000"/></a:xfrm>
          <a:prstGeom prst="roundRect"><a:avLst><a:gd name="adj" fmla="val 1500"/></a:avLst></a:prstGeom>
          <a:solidFill><a:srgbClr val="F8FAFC"/></a:solidFill>
          <a:ln w="12700"><a:solidFill><a:srgbClr val="CBD5E1"/></a:solidFill></a:ln>
        </p:spPr>
        <p:txBody>
          <a:bodyPr lIns="250000" tIns="250000" rIns="250000" bIns="250000"/>
          <a:lstStyle/>
          <a:p>
            <a:r><a:rPr sz="1500" b="1"><a:solidFill><a:srgbClr val="1E293B"/></a:solidFill></a:rPr>
            <a:t>EVALUASI TREN &amp; INTELIJEN BISNIS</a:t></a:r>
          </a:p>
          <a:p>
            <a:r><a:rPr sz="1300"><a:solidFill><a:srgbClr val="475569"/></a:solidFill></a:rPr>
            <a:t>Status Tren: ${xmlEscape(insights.trendStatus)} | Stabilitas: ${xmlEscape(insights.stabilityLevel)}</a:t></a:r>
          </a:p>
          <a:p><a:r><a:rPr sz="500"/><a:t></a:t></a:r></a:p>
          <a:p>
            <a:r><a:rPr sz="1400"><a:solidFill><a:srgbClr val="0F172A"/></a:solidFill></a:rPr>
            <a:t>${xmlEscape(insights.executiveSummary)}</a:t></a:r>
          </a:p>
          <a:p><a:r><a:rPr sz="800"/><a:t></a:t></a:r></a:p>
          <a:p>
            <a:r><a:rPr sz="1300" b="1"><a:solidFill><a:srgbClr val="2563EB"/></a:solidFill></a:rPr>
            <a:t>Rekomendasi Taktis:</a:t></a:r>
          </a:p>
          <a:p>
            <a:r><a:rPr sz="1250"><a:solidFill><a:srgbClr val="334155"/></a:solidFill></a:rPr>
            <a:t>• ${xmlEscape(insights.strategicRecommendations.isNotEmpty ? insights.strategicRecommendations.first : "Pertahankan ketersediaan stok barang terlaris.")}</a:t></a:r>
          </a:p>
        </p:txBody>
      </p:sp>
    </p:spTree>
  </p:cSld>
  <p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>
</p:sld>''';
    archive.addFile(ArchiveFile('ppt/slides/slide2.xml', slide2Xml.length, slide2Xml.codeUnits));

    // SLIDE 3: KHUSUS DIAGRAM BATANG PENJUALAN (BAR CHART SLIDE)
    final slide3Xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:cSld>
    <p:spTree>
      <p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>
      <p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>
      <p:sp>
        <p:nvSpPr><p:cNvPr id="2" name="Title"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr>
        <p:spPr><a:xfrm><a:off x="800000" y="500000"/><a:ext cx="10592000" cy="700000"/></a:xfrm></p:spPr>
        <p:txBody>
          <a:bodyPr/><a:lstStyle/>
          <a:p>
            <a:r><a:rPr sz="2300" b="1"><a:solidFill><a:srgbClr val="0F172A"/></a:solidFill></a:rPr>
            <a:t>DIAGRAM BATANG: OMSET PENJUALAN PER PERIODE</a:t></a:r>
          </a:p>
          <a:p>
            <a:r><a:rPr sz="1200"><a:solidFill><a:srgbClr val="64748B"/></a:solidFill></a:rPr>
            <a:t>Perbandingan total pendapatan kotor antar titik periode penjualan</a:t></a:r>
          </a:p>
        </p:txBody>
      </p:sp>

      <!-- Gambar Diagram Batang -->
      <p:pic>
        <p:nvPicPr>
          <p:cNvPr id="4" name="BarChartImage"/>
          <p:cNvPicPr><a:picLocks noChangeAspect="1"/></p:cNvPicPr>
          <p:nvPr/>
        </p:nvPicPr>
        <p:blipFill>
          <a:blip r:embed="rId2"/>
          <a:stretch><a:fillRect/></a:stretch>
        </p:blipFill>
        <p:spPr>
          <a:xfrm>
            <a:off x="800000" y="1300000"/>
            <a:ext cx="10592000" cy="5000000"/>
          </a:xfrm>
          <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
        </p:spPr>
      </p:pic>
    </p:spTree>
  </p:cSld>
  <p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>
</p:sld>''';
    archive.addFile(ArchiveFile('ppt/slides/slide3.xml', slide3Xml.length, slide3Xml.codeUnits));

    // SLIDE 4: KHUSUS DIAGRAM GARIS TREN PENJUALAN (LINE CHART SLIDE)
    final slide4Xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:cSld>
    <p:spTree>
      <p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>
      <p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>
      <p:sp>
        <p:nvSpPr><p:cNvPr id="2" name="Title"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr>
        <p:spPr><a:xfrm><a:off x="800000" y="500000"/><a:ext cx="10592000" cy="700000"/></a:xfrm></p:spPr>
        <p:txBody>
          <a:bodyPr/><a:lstStyle/>
          <a:p>
            <a:r><a:rPr sz="2300" b="1"><a:solidFill><a:srgbClr val="0F172A"/></a:solidFill></a:rPr>
            <a:t>DIAGRAM GARIS: TREN PERTUMBUHAN PENJUALAN</a:t></a:r>
          </a:p>
          <a:p>
            <a:r><a:rPr sz="1200"><a:solidFill><a:srgbClr val="64748B"/></a:solidFill></a:rPr>
            <a:t>Fluktuasi dan kontinuitas arah momentum performa bisnis</a:t></a:r>
          </a:p>
        </p:txBody>
      </p:sp>

      <!-- Gambar Diagram Garis -->
      <p:pic>
        <p:nvPicPr>
          <p:cNvPr id="5" name="LineChartImage"/>
          <p:cNvPicPr><a:picLocks noChangeAspect="1"/></p:cNvPicPr>
          <p:nvPr/>
        </p:nvPicPr>
        <p:blipFill>
          <a:blip r:embed="rId2"/>
          <a:stretch><a:fillRect/></a:stretch>
        </p:blipFill>
        <p:spPr>
          <a:xfrm>
            <a:off x="800000" y="1300000"/>
            <a:ext cx="10592000" cy="5000000"/>
          </a:xfrm>
          <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
        </p:spPr>
      </p:pic>
    </p:spTree>
  </p:cSld>
  <p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>
</p:sld>''';
    archive.addFile(ArchiveFile('ppt/slides/slide4.xml', slide4Xml.length, slide4Xml.codeUnits));

    // SLIDE 5: Rincian Angka & Top Produk Terlaris (Dua Kolom)
    final pointsSubset = summary.dataPoints.take(12).toList();
    final topProdSubset = summary.topProducts.take(8).toList();

    final slide5Xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:cSld>
    <p:spTree>
      <p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>
      <p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>
      <p:sp>
        <p:nvSpPr><p:cNvPr id="2" name="Title"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr>
        <p:spPr><a:xfrm><a:off x="800000" y="500000"/><a:ext cx="10592000" cy="600000"/></a:xfrm></p:spPr>
        <p:txBody>
          <a:bodyPr/><a:lstStyle/>
          <a:p>
            <a:r><a:rPr sz="2400" b="1"><a:solidFill><a:srgbClr val="0F172A"/></a:solidFill></a:rPr>
            <a:t>RINCIAN DATA TITIK PENJUALAN &amp; TOP PRODUK</a:t></a:r>
          </a:p>
        </p:txBody>
      </p:sp>

      <!-- Kolom Kiri: Rincian Titik Penjualan -->
      <p:sp>
        <p:nvSpPr><p:cNvPr id="3" name="LeftBox"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr>
        <p:spPr>
          <a:xfrm><a:off x="800000" y="1300000"/><a:ext cx="5100000" cy="4900000"/></a:xfrm>
          <a:prstGeom prst="roundRect"><a:avLst><a:gd name="adj" fmla="val 1500"/></a:avLst></a:prstGeom>
          <a:solidFill><a:srgbClr val="FFFFFF"/></a:solidFill>
          <a:ln w="12700"><a:solidFill><a:srgbClr val="CBD5E1"/></a:solidFill></a:ln>
        </p:spPr>
        <p:txBody>
          <a:bodyPr lIns="200000" tIns="200000" rIns="200000" bIns="200000"/>
          <a:lstStyle/>
          <a:p>
            <a:r><a:rPr sz="1500" b="1"><a:solidFill><a:srgbClr val="1E293B"/></a:solidFill></a:rPr>
            <a:t>Rincian Omset per Periode</a:t></a:r>
          </a:p>
          <a:p><a:r><a:rPr sz="400"/><a:t></a:t></a:r></a:p>
          ${pointsSubset.map((p) => '''
          <a:p>
            <a:r><a:rPr sz="1150"><a:solidFill><a:srgbClr val="334155"/></a:solidFill></a:rPr>
            <a:t>• ${xmlEscape(p.label)}: ${xmlEscape(CurrencyFormat.convertToIdr(p.totalAmount, 0))} (${p.transactionCount} transaksi)</a:t></a:r>
          </a:p>''').join('')}
        </p:txBody>
      </p:sp>

      <!-- Kolom Kanan: Top Produk Terlaris -->
      <p:sp>
        <p:nvSpPr><p:cNvPr id="4" name="RightBox"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr>
        <p:spPr>
          <a:xfrm><a:off x="6300000" y="1300000"/><a:ext cx="5100000" cy="4900000"/></a:xfrm>
          <a:prstGeom prst="roundRect"><a:avLst><a:gd name="adj" fmla="val 1500"/></a:avLst></a:prstGeom>
          <a:solidFill><a:srgbClr val="FFFFFF"/></a:solidFill>
          <a:ln w="12700"><a:solidFill><a:srgbClr val="CBD5E1"/></a:solidFill></a:ln>
        </p:spPr>
        <p:txBody>
          <a:bodyPr lIns="200000" tIns="200000" rIns="200000" bIns="200000"/>
          <a:lstStyle/>
          <a:p>
            <a:r><a:rPr sz="1500" b="1"><a:solidFill><a:srgbClr val="1E293B"/></a:solidFill></a:rPr>
            <a:t>Top Produk Terlaris</a:t></a:r>
          </a:p>
          <a:p><a:r><a:rPr sz="400"/><a:t></a:t></a:r></a:p>
          ${topProdSubset.map((it) => '''
          <a:p>
            <a:r><a:rPr sz="1150"><a:solidFill><a:srgbClr val="334155"/></a:solidFill></a:rPr>
            <a:t>#${topProdSubset.indexOf(it) + 1} ${xmlEscape(it['product_name'] ?? '-')}: ${it['total_qty'] ?? 0} pcs terjual</a:t></a:r>
          </a:p>''').join('')}
        </p:txBody>
      </p:sp>
    </p:spTree>
  </p:cSld>
  <p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>
</p:sld>''';
    archive.addFile(ArchiveFile('ppt/slides/slide5.xml', slide5Xml.length, slide5Xml.codeUnits));

    // Encode ZIP menjadi file .pptx
    final encoder = ZipEncoder();
    final pptxBytes = encoder.encode(archive);

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/ANALISIS_NANDACELL_$timestamp.pptx');
    if (pptxBytes != null) {
      await file.writeAsBytes(pptxBytes);
    }
    return file;
  }

  // =========================================================================
  // 4. MODAL DIALOG PILIHAN FORMAT EXPORT
  // =========================================================================
  static void showExportModal(
    BuildContext context,
    SalesAnalyticsSummary summary,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ExportModalWidget(summary: summary),
    );
  }
}

class _ExportModalWidget extends StatefulWidget {
  final SalesAnalyticsSummary summary;

  const _ExportModalWidget({required this.summary});

  @override
  State<_ExportModalWidget> createState() => _ExportModalWidgetState();
}

class _ExportModalWidgetState extends State<_ExportModalWidget> {
  bool _isExporting = false;
  String? _exportingFormat;

  Future<void> _handleExport(String format) async {
    setState(() {
      _isExporting = true;
      _exportingFormat = format;
    });

    try {
      File file;
      final service = SalesAnalyticsExportService.instance;

      if (format == 'pdf') {
        file = await service.exportToPdf(widget.summary);
      } else if (format == 'excel') {
        file = await service.exportToExcel(widget.summary);
      } else {
        file = await service.exportToPptx(widget.summary);
      }

      if (mounted) {
        Navigator.pop(context);
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Hasil Analisis Penjualan - ${widget.summary.periodTitle}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportingFormat = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.file_download_rounded,
                  color: Color(0xFF2563EB),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih Format Ekspor Analisis',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Masing-masing format dilengkapi diagram batang & garis',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 1. OPSI PDF
          _buildExportOptionCard(
            title: 'Dokumen PDF (.pdf)',
            subtitle: 'Laporan resmi 2 halaman dengan grafik visual & tabel lengkap',
            icon: Icons.picture_as_pdf_rounded,
            color: const Color(0xFFDC2626),
            bgColor: const Color(0xFFFEF2F2),
            format: 'pdf',
          ),
          const SizedBox(height: 12),

          // 2. OPSI EXCEL
          _buildExportOptionCard(
            title: 'Spreadsheet Excel (.xlsx)',
            subtitle: 'Workbook finansial multi-sheet dengan visual data bars & sparkline tren',
            icon: Icons.table_chart_rounded,
            color: const Color(0xFF059669),
            bgColor: const Color(0xFFECFDF5),
            format: 'excel',
          ),
          const SizedBox(height: 12),

          // 3. OPSI POWERPOINT
          _buildExportOptionCard(
            title: 'Presentasi PowerPoint (.pptx)',
            subtitle: '5 slide 16:9 widescreen dengan slide khusus diagram batang & garis',
            icon: Icons.slideshow_rounded,
            color: const Color(0xFFEA580C),
            bgColor: const Color(0xFFFFF7ED),
            format: 'pptx',
          ),
        ],
      ),
    );
  }

  Widget _buildExportOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String format,
  }) {
    final isLoadingThis = _isExporting && _exportingFormat == format;

    return InkWell(
      onTap: _isExporting ? null : () => _handleExport(format),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            if (isLoadingThis)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
          ],
        ),
      ),
    );
  }
}
