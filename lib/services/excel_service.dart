import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../models/product_model.dart';

class ExcelService {
  Future<String?> exportProductToExcel(List<Product> products) async {
    var excel = Excel.createExcel();

    // Ganti nama sheet agar lebih rapi
    String sheetName = "Stok Barang Nanda Cell";
    Sheet sheetObject = excel[sheetName];
    excel.delete('Sheet1');

    // 1. Tambahkan Header (Disesuaikan dengan field model kamu)
    sheetObject.appendRow([
      TextCellValue('ID'),
      TextCellValue('Kode/Barcode'),
      TextCellValue('Nama Produk'),
      TextCellValue('Kategori'),
      TextCellValue('Harga Jual (Rp)'),
      TextCellValue('Sisa Stok'),
    ]);

    // 2. Styling Header (Opsional, agar terlihat lebih premium)
    // Kamu bisa skip bagian styling ini jika ingin cepat
    var headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString(
        '#4F46E5',
      ), // Indigo-600 seperti UI React tadi
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );

    for (var i = 0; i < 6; i++) {
      var cell = sheetObject.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.cellStyle = headerStyle;
    }

    // 3. Masukkan Data dari List<Product>
    for (var p in products) {
      sheetObject.appendRow([
        IntCellValue(p.id),
        TextCellValue(p.code), // Masukkan field 'code'
        TextCellValue(p.name),
        TextCellValue(p.category),
        IntCellValue(p.price),
        IntCellValue(p.stock),
      ]);
    }

    // 4. Proses Simpan File
    try {
      var fileBytes = excel.save();
      Directory? directory;

      if (Platform.isAndroid) {
        // Gunakan path yang aman untuk Android 13/14 (Samsung A55)
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        String timestamp = DateTime.now()
            .toString()
            .replaceAll(RegExp(r'[:.-]'), '')
            .substring(0, 14);
        String filePath = "${directory.path}/STOK_NANDACELL_$timestamp.xlsx";

        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes!);

        return filePath;
      }
    } catch (e) {
      print("Error Export Excel: $e");
    }
    return null;
  }
}
