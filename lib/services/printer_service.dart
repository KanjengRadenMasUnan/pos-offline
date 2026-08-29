import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';

import '../models/cart_item_model.dart';
import 'local_db_service.dart'; // [TAMBAHAN]: Import database lokal

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
    // [TAMBAHAN]: Ambil pengaturan struk dari database
    final settings = await LocalDbService.instance.getReceiptSettings();
    final is80mm = settings['paper_size'] == 80;

    final profile = await CapabilityProfile.load();
    // [TAMBAHAN]: Sesuaikan ukuran kertas dinamis (58mm atau 80mm)
    final generator = Generator(
      is80mm ? PaperSize.mm80 : PaperSize.mm58,
      profile,
    );
    final bytes = <int>[];

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Build Sequence (Melempar data settings ke builder)
    bytes.addAll(_buildHeader(generator, settings, is80mm));
    bytes.addAll(_buildInvoiceInfo(generator, invoice, is80mm));
    bytes.addAll(_buildItemsList(generator, items, is80mm));
    bytes.addAll(
      _buildTotalSection(generator, currencyFormatter, total, is80mm),
    );
    bytes.addAll(_buildFooter(generator, settings));

    return bytes;
  }

  // --- COMPONENT BUILDERS ---

  List<int> _buildHeader(
    Generator generator,
    Map<String, dynamic> settings,
    bool is80mm,
  ) {
    final bytes = <int>[];
    String dashLine = is80mm
        ? '------------------------------------------------'
        : '--------------------------------';

    bytes.addAll(
      generator.text(
        settings['store_name'], // [TAMBAHAN]: Nama toko dinamis
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    );

    if (settings['store_address'].toString().isNotEmpty) {
      bytes.addAll(
        generator.text(
          settings['store_address'], // [TAMBAHAN]: Alamat dinamis
          styles: const PosStyles(align: PosAlign.center, bold: false),
        ),
      );
    }

    if (settings['store_contact'].toString().isNotEmpty) {
      bytes.addAll(
        generator.text(
          settings['store_contact'], // [TAMBAHAN]: Kontak dinamis
          styles: const PosStyles(align: PosAlign.center, bold: false),
        ),
      );
    }

    bytes.addAll(
      generator.text(
        dashLine, // [TAMBAHAN]: Garis dinamis menyesuaikan kertas
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    return bytes;
  }

  List<int> _buildInvoiceInfo(
    Generator generator,
    String invoice,
    bool is80mm,
  ) {
    final bytes = <int>[];
    String dashLine = is80mm
        ? '------------------------------------------------'
        : '--------------------------------';

    // Sesuaikan lebar kolom grid berdasarkan ukuran kertas
    int leftWidth = is80mm ? 6 : 6;
    int rightWidth = is80mm ? 6 : 6;

    bytes.addAll(
      generator.row([
        PosColumn(text: 'No: $invoice', width: leftWidth),
        PosColumn(
          text: DateFormat('dd/MM/yy HH:mm').format(DateTime.now()),
          width: rightWidth,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]),
    );
    bytes.addAll(
      generator.text(dashLine, styles: const PosStyles(align: PosAlign.center)),
    );
    return bytes;
  }

  List<int> _buildItemsList(
    Generator generator,
    List<CartItem> items,
    bool is80mm,
  ) {
    final bytes = <int>[];
    String dashLine = is80mm
        ? '------------------------------------------------'
        : '--------------------------------';

    for (final item in items) {
      bytes.addAll(
        generator.text(
          item.product.name.toUpperCase(),
          styles: const PosStyles(bold: false),
        ),
      );

      int leftWidth = is80mm ? 8 : 7;
      int rightWidth = is80mm ? 4 : 5;

      bytes.addAll(
        generator.row([
          PosColumn(
            text: '  ${item.qty} x ${item.product.price}',
            width: leftWidth,
            styles: const PosStyles(bold: false),
          ),
          PosColumn(
            text: '${item.qty * item.product.price}',
            width: rightWidth,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
      );
    }
    bytes.addAll(
      generator.text(dashLine, styles: const PosStyles(align: PosAlign.center)),
    );
    return bytes;
  }

  List<int> _buildTotalSection(
    Generator generator,
    NumberFormat currencyFormatter,
    int total,
    bool is80mm,
  ) {
    final bytes = <int>[];
    String equalsLine = is80mm
        ? '================================================'
        : '================================';

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
        equalsLine,
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    return bytes;
  }

  List<int> _buildFooter(Generator generator, Map<String, dynamic> settings) {
    final bytes = <int>[];

    if (settings['footer_message'].toString().isNotEmpty) {
      bytes.addAll(
        generator.text(
          settings['footer_message'], // [TAMBAHAN]: Footer dinamis
          styles: const PosStyles(align: PosAlign.center),
        ),
      );
    }

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
