import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';

import '../models/cart_item_model.dart';

class PrinterService {
  // --- CONNECTION METHODS ---

  Future<bool> checkConnection() async {
    return await PrintBluetoothThermal.bluetoothEnabled;
  }

  Future<List<BluetoothInfo>> getPairedDevices() async {
    return await PrintBluetoothThermal.pairedBluetooths;
  }

  Future<bool> connect(String macAddress) async {
    try {
      final isConnected = await PrintBluetoothThermal.connectionStatus;
      if (isConnected) return true;

      return await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
    } catch (_) {
      return false;
    }
  }

  // --- PRINTING EXECUTION ---

  Future<void> printStruk(
    String invoice,
    List<CartItem> items,
    int total,
  ) async {
    final isConnected = await PrintBluetoothThermal.connectionStatus;

    if (!isConnected) {
      throw Exception('Printer belum terhubung');
    }

    final bytes = await _generateTicket(
      invoice: invoice,
      items: items,
      total: total,
    );

    await PrintBluetoothThermal.writeBytes(bytes);
  }

  // --- TICKET GENERATION LOGIC ---

  Future<List<int>> _generateTicket({
    required String invoice,
    required List<CartItem> items,
    required int total,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final bytes = <int>[];

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Build Sequence
    bytes.addAll(_buildHeader(generator));
    bytes.addAll(_buildInvoiceInfo(generator, invoice));
    bytes.addAll(_buildItemsList(generator, items));
    bytes.addAll(_buildTotalSection(generator, currencyFormatter, total));
    bytes.addAll(_buildFooter(generator));

    return bytes;
  }

  // --- COMPONENT BUILDERS ---

  List<int> _buildHeader(Generator generator) {
    final bytes = <int>[];
    bytes.addAll(
      generator.text(
        'NANDA CELL',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    );
    bytes.addAll(
      generator.text(
        'Pusat Accessories & Service HP',
        styles: const PosStyles(align: PosAlign.center, bold: false),
      ),
    );
    // Tambahan info kontak agar lebih profesional
    bytes.addAll(
      generator.text(
        'WhatsApp: 08xx-xxxx-xxxx',
        styles: const PosStyles(align: PosAlign.center, bold: false),
      ),
    );
    bytes.addAll(
      generator.text(
        '--------------------------------',
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    return bytes;
  }

  List<int> _buildInvoiceInfo(Generator generator, String invoice) {
    final bytes = <int>[];
    // Format rata kiri-kanan untuk Invoice dan Tanggal
    bytes.addAll(
      generator.row([
        PosColumn(text: 'No: $invoice', width: 6),
        PosColumn(
          text: DateFormat('dd/MM/yy HH:mm').format(DateTime.now()),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]),
    );
    bytes.addAll(
      generator.text(
        '--------------------------------',
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    return bytes;
  }

  List<int> _buildItemsList(Generator generator, List<CartItem> items) {
    final bytes = <int>[];
    for (final item in items) {
      // Baris 1: Nama Produk (Full Width)
      bytes.addAll(
        generator.text(
          item.product.name.toUpperCase(),
          styles: const PosStyles(bold: false),
        ),
      );
      // Baris 2: Detail Qty x Harga dan Subtotal
      bytes.addAll(
        generator.row([
          PosColumn(
            text: '  ${item.qty} x ${item.product.price}',
            width: 7,
            // Hapus parameter italic di sini
            styles: const PosStyles(bold: false),
          ),
          PosColumn(
            text: '${item.qty * item.product.price}',
            width: 5,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
      );
    }
    bytes.addAll(
      generator.text(
        '--------------------------------',
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    return bytes;
  }

  List<int> _buildTotalSection(
    Generator generator,
    NumberFormat currencyFormatter,
    int total,
  ) {
    final bytes = <int>[];
    bytes.addAll(
      generator.row([
        PosColumn(
          text: 'TOTAL AKHIR',
          width: 6,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          text: currencyFormatter.format(total),
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]),
    );
    bytes.addAll(
      generator.text(
        '================================',
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    return bytes;
  }

  List<int> _buildFooter(Generator generator) {
    final bytes = <int>[];

    bytes.addAll(
      generator.text(
        'Terima Kasih Atas Kunjungan Anda',
        // Hapus parameter italic di sini juga
        styles: const PosStyles(align: PosAlign.center),
      ),
    );

    bytes.addAll(generator.feed(1));

    bytes.addAll(
      generator.text(
        'UNTUK KLAIM GARANSI',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ),
    );

    bytes.addAll(
      generator.text(
        'PASTIKAN STRUK INI TIDAK HILANG',
        styles: const PosStyles(
          align: PosAlign.center,
          fontType: PosFontType.fontB,
        ),
      ),
    );

    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());

    return bytes;
  }
}
