import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class ReportPdfService {
  Future<File> generateReportPdf({
    required String reportTitle,
    required String period,
    required int totalIncome,
    required List<Map<String, dynamic>> topSelling,
    required List<Map<String, dynamic>> soldItems,
    required List<Map<String, dynamic>> lowStock,
    required List<Map<String, dynamic>> outOfStock,
  }) async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // HEADER
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'NANDA CELL',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text('Laporan Penjualan', style: pw.TextStyle(fontSize: 14)),
                pw.Text(
                  reportTitle,
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                ),
                pw.Text('Periode: $period', style: pw.TextStyle(fontSize: 11)),
                pw.Divider(),
              ],
            ),
          ),

          // TOTAL PENDAPATAN
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total Pendapatan',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                pw.Text(
                  currencyFormat.format(totalIncome),
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                    color: PdfColors.blue,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // BARANG PALING LARIS
          pw.Text(
            'Barang Paling Laris',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
          ),
          pw.SizedBox(height: 6),
          if (topSelling.isEmpty)
            pw.Text('Tidak ada data', style: const pw.TextStyle(fontSize: 10))
          else
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              data: [
                ['Nama Produk', 'Jumlah'],
                ...topSelling.map(
                  (item) => [
                    item['product_name']?.toString() ?? '',
                    '${item['total_qty']}x',
                  ],
                ),
              ],
            ),
          pw.SizedBox(height: 16),

          // DAFTAR BARANG TERJUAL
          pw.Text(
            'Daftar Barang Terjual',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
          ),
          pw.SizedBox(height: 6),
          if (soldItems.isEmpty)
            pw.Text(
              'Tidak ada transaksi',
              style: const pw.TextStyle(fontSize: 10),
            )
          else
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              data: [
                ['Nama Produk', 'Qty', 'Subtotal'],
                ...soldItems.map(
                  (item) => [
                    item['product_name']?.toString() ?? '',
                    '${item['total_qty']}',
                    currencyFormat.format(item['total_sales'] ?? 0).toString(),
                  ],
                ),
              ],
            ),
          pw.SizedBox(height: 16),

          // STOK MENIPIS
          pw.Text(
            'Stok Menipis (≤ 5)',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
          ),
          pw.SizedBox(height: 6),
          if (lowStock.isEmpty)
            pw.Text('Semua stok aman', style: const pw.TextStyle(fontSize: 10))
          else
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              data: [
                ['Nama Produk', 'Stok'],
                ...lowStock.map(
                  (item) => [
                    item['name']?.toString() ?? '',
                    '${item['stock']}',
                  ],
                ),
              ],
            ),
          pw.SizedBox(height: 16),

          // STOK KOSONG
          pw.Text(
            'Stok Kosong',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
          ),
          pw.SizedBox(height: 6),
          if (outOfStock.isEmpty)
            pw.Text(
              'Tidak ada barang kosong',
              style: const pw.TextStyle(fontSize: 10),
            )
          else
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              data: [
                ['Nama Produk'],
                ...outOfStock.map((item) => [item['name']?.toString() ?? '']),
              ],
            ),
        ],
      ),
    );

    // Simpan ke file sementara
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/laporan_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
