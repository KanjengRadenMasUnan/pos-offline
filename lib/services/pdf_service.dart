import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/product_model.dart';
import 'security_service.dart';

class PdfService {
  // --- DIALOG METHODS ---

  Future<void> printWithDialog(BuildContext context, Product product) async {
    final qtyController = TextEditingController(text: '1');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cetak Label Satuan'),
        content: TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Jumlah Stiker',
            suffixText: 'pcs',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final qty = int.tryParse(qtyController.text) ?? 1;
              await _generatePdfRoll([product], qty);
            },
            child: const Text('CETAK'),
          ),
        ],
      ),
    );
  }

  // --- BULK PRINTING METHODS ---

  Future<void> printBulkLabels(List<Product> products) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(15),
        build: (pw.Context context) {
          return [
            pw.GridView(
              crossAxisCount: 5,
              childAspectRatio: 0.8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: products
                  .map((product) => _buildSticker(product, isMini: true))
                  .toList(),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Label-Massal-A4',
    );
  }

  // --- PDF GENERATION METHODS ---

  Future<void> _generatePdfRoll(List<Product> products, int qty) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(5),
        build: (pw.Context context) {
          return pw.Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(
              qty,
              (index) => _buildSticker(products[0], isMini: false),
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => doc.save(),
      name: 'Label-Roll',
    );
  }

  // --- STICKER BUILDING METHODS ---

  pw.Widget _buildSticker(Product product, {required bool isMini}) {
    const borderWidth = 0.5;
    const borderRadius = 4.0;
    const containerPadding = 4.0;
    const spacingHeight = 2.0;

    final size = isMini ? 40.0 : 60.0;
    final fontSize = isMini ? 7.0 : 9.0;
    final containerWidth = isMini ? null : 120.0;

    return pw.Container(
      width: containerWidth,
      padding: const pw.EdgeInsets.all(containerPadding),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey, width: borderWidth),
        borderRadius: pw.BorderRadius.circular(borderRadius),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            'Nanda Cell',
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: spacingHeight),
          pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data: SecurityService.encryptData(product.code),
            width: size,
            height: size,
          ),
          pw.SizedBox(height: spacingHeight),
          pw.Text(
            product.name,
            style: pw.TextStyle(fontSize: fontSize),
            textAlign: pw.TextAlign.center,
            maxLines: 2,
            overflow: pw.TextOverflow.clip,
          ),
        ],
      ),
    );
  }
}
