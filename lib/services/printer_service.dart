import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';

import '../models/cart_item_model.dart';
import 'local_db_service.dart';

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
    final settings = await LocalDbService.instance.getReceiptSettings();
    final profile = await CapabilityProfile.load();
    
    // Kertas dipatenkan ke 58mm
    final generator = Generator(PaperSize.mm58, profile);
    final bytes = <int>[];

    // Format Rupiah rapi (Tanpa simbol Rp untuk item, dengan Rp untuk total)
    final numFormat = NumberFormat('#,##0', 'id_ID');
    final rpFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Build Sequence
    bytes.addAll(_buildHeader(generator, settings));
    bytes.addAll(_buildInvoiceInfo(generator, invoice));
    bytes.addAll(_buildItemsList(generator, items, numFormat));
    bytes.addAll(_buildTotalSection(generator, total, rpFormat));
    bytes.addAll(_buildFooter(generator, settings));

    return bytes;
  }

  // --- COMPONENT BUILDERS ---

  List<int> _buildHeader(Generator generator, Map<String, dynamic> settings) {
    final bytes = <int>[];
    const String dashLine = '--------------------------------'; // Tepat 32 karakter

    // Nama Toko (Besar dan Tebal)
    bytes.addAll(
      generator.text(
        settings['store_name'],
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          fontType: PosFontType.fontA, // Kunci ke Font Normal
        ),
      ),
    );
    
    // Alamat Toko
    if (settings['store_address'].toString().isNotEmpty) {
      bytes.addAll(
        generator.text(
          settings['store_address'],
          styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontA),
        ),
      );
    }
    
    // Kontak Toko
    if (settings['store_contact'].toString().isNotEmpty) {
      bytes.addAll(
        generator.text(
          settings['store_contact'],
          styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontA),
        ),
      );
    }

    bytes.addAll(generator.feed(1)); // Spasi 1 baris
    bytes.addAll(
      generator.text(
        dashLine,
        styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontA),
      ),
    );
    return bytes;
  }

  List<int> _buildInvoiceInfo(Generator generator, String invoice) {
    final bytes = <int>[];
    const String dashLine = '--------------------------------';
    
    // Di 58mm, No Struk dan Tanggal ditumpuk atas-bawah agar tidak tabrakan
    bytes.addAll(
      generator.text(
        'No  : $invoice',
        styles: const PosStyles(fontType: PosFontType.fontA),
      ),
    );
    bytes.addAll(
      generator.text(
        'Tgl : ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}',
        styles: const PosStyles(fontType: PosFontType.fontA),
      ),
    );

    bytes.addAll(
      generator.text(
        dashLine,
        styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontA),
      ),
    );
    return bytes;
  }

  List<int> _buildItemsList(Generator generator, List<CartItem> items, NumberFormat numFormat) {
    final bytes = <int>[];
    const String dashLine = '--------------------------------';
    
    for (final item in items) {
      // Baris 1: Nama Produk (Bold agar menonjol)
      bytes.addAll(
        generator.text(
          item.product.name.toUpperCase(),
          styles: const PosStyles(bold: true, fontType: PosFontType.fontA),
        ),
      );
      
      // Baris 2: Qty x Harga (Kiri) & Subtotal (Kanan)
      bytes.addAll(
        generator.row([
          PosColumn(
            text: '${item.qty} x ${numFormat.format(item.product.price)}',
            width: 7, // Lebar kiri 7/12
            styles: const PosStyles(fontType: PosFontType.fontA),
          ),
          PosColumn(
            text: numFormat.format(item.qty * item.product.price),
            width: 5, // Lebar kanan 5/12
            styles: const PosStyles(align: PosAlign.right, fontType: PosFontType.fontA),
          ),
        ]),
      );
    }
    
    bytes.addAll(
      generator.text(
        dashLine,
        styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontA),
      ),
    );
    return bytes;
  }

  List<int> _buildTotalSection(
    Generator generator,
    int total,
    NumberFormat rpFormat
  ) {
    final bytes = <int>[];
    const String equalLine = '================================';

    // Baris Total Akhir
    bytes.addAll(
      generator.row([
        PosColumn(
          text: 'TOTAL',
          width: 5,
          styles: const PosStyles(bold: true, fontType: PosFontType.fontA),
        ),
        PosColumn(
          text: rpFormat.format(total),
          width: 7,
          styles: const PosStyles(align: PosAlign.right, bold: true, fontType: PosFontType.fontA),
        ),
      ]),
    );

    bytes.addAll(
      generator.text(
        equalLine,
        styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontA),
      ),
    );
    return bytes;
  }

  List<int> _buildFooter(Generator generator, Map<String, dynamic> settings) {
    final bytes = <int>[];

    // Pesan Terima Kasih
    if (settings['footer_message'].toString().isNotEmpty) {
      bytes.addAll(
        generator.text(
          settings['footer_message'],
          styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontA),
        ),
      );
    }

    bytes.addAll(generator.feed(1));

    // Ketentuan Garansi (Hanya dimunculkan jika ini konter HP)
    bytes.addAll(
      generator.text(
        'UNTUK KLAIM GARANSI',
        styles: const PosStyles(align: PosAlign.center, bold: true, fontType: PosFontType.fontA),
      ),
    );
    bytes.addAll(
      generator.text(
        'Harap bawa struk ini',
        styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontA),
      ),
    );

    // Kertas didorong keluar 3 baris agar mudah disobek
    bytes.addAll(generator.feed(3));
    bytes.addAll(generator.cut());

    return bytes;
  }
}
