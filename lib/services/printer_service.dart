import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;

import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../models/receipt_custom_model.dart';
import 'receipt_custom_service.dart';

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
    int total, {
    int? cashPaid,
    int? change,
  }) async {
    final isConnected = await PrintBluetoothThermal.connectionStatus;

    if (!isConnected) {
      throw Exception('Printer belum terhubung');
    }

    final bytes = await _generateTicket(
      invoice: invoice,
      items: items,
      total: total,
      cashPaid: cashPaid,
      change: change,
    );

    await PrintBluetoothThermal.writeBytes(bytes);
  }

  /// Cetak struk uji coba kustomisasi 58mm
  Future<void> printTestSampleStruk(ReceiptCustomModel config) async {
    final isConnected = await PrintBluetoothThermal.connectionStatus;

    if (!isConnected) {
      throw Exception('Printer Bluetooth belum terhubung.');
    }

    final sampleItems = [
      CartItem(
        product: Product(id: 1, code: 'PRD-001', name: 'Kopi Susu Gula Aren', price: 18000, stock: 99, category: 'Minuman'),
        qty: 2,
      ),
      CartItem(
        product: Product(id: 2, code: 'PRD-002', name: 'Croissant Coklat Butter', price: 24000, stock: 50, category: 'Makanan'),
        qty: 1,
      ),
      CartItem(
        product: Product(id: 3, code: 'PRD-003', name: 'Air Mineral 600ml', price: 5000, stock: 100, category: 'Minuman'),
        qty: 1,
      ),
    ];
    final sampleTotal = (2 * 18000) + 24000 + 5000;

    final bytes = await _generateCustomTicket(
      config: config,
      invoice: 'INV-TEST-${DateFormat('HHmm').format(DateTime.now())}',
      items: sampleItems,
      total: sampleTotal,
      cashPaid: 100000,
      change: 35000,
    );

    await PrintBluetoothThermal.writeBytes(bytes);
  }

  // --- TICKET GENERATION LOGIC ---

  Future<List<int>> _generateTicket({
    required String invoice,
    required List<CartItem> items,
    required int total,
    int? cashPaid,
    int? change,
  }) async {
    final config = await ReceiptCustomService.instance.getConfig();
    return _generateCustomTicket(
      config: config,
      invoice: invoice,
      items: items,
      total: total,
      cashPaid: cashPaid,
      change: change,
    );
  }

  Future<List<int>> _generateCustomTicket({
    required ReceiptCustomModel config,
    required String invoice,
    required List<CartItem> items,
    required int total,
    int? cashPaid,
    int? change,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final bytes = <int>[];

    final numFormat = NumberFormat('#,##0', 'id_ID');
    final rpFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    img.Image? logoImg;
    if (config.showLogo && config.logoPath != null) {
      logoImg = await ReceiptCustomService.instance.loadAndProcessLogoImage(
        config.logoPath,
        config.logoSize.pixelWidth,
      );
    }

    PosAlign alignForLogo(ReceiptLogoAlign a) {
      switch (a) {
        case ReceiptLogoAlign.left:
          return PosAlign.left;
        case ReceiptLogoAlign.right:
          return PosAlign.right;
        case ReceiptLogoAlign.center:
          return PosAlign.center;
      }
    }

    void insertLogoIfPosition(ReceiptLogoPosition pos) {
      if (!config.showLogo) return;
      if (config.logoPosition != pos) return;

      if (logoImg != null) {
        bytes.addAll(generator.image(logoImg, align: alignForLogo(config.logoAlignment)));
        bytes.addAll(generator.feed(1));
      } else {
        bytes.addAll(
          generator.text(
            '*** POS OFFICIAL ***',
            styles: PosStyles(
              align: alignForLogo(config.logoAlignment),
              bold: true,
              fontType: PosFontType.fontA,
            ),
          ),
        );
      }
    }

    final divider = config.dividerStyle.pattern;

    // 1. Posisi Logo: TOP (Sebelum Header)
    insertLogoIfPosition(ReceiptLogoPosition.top);

    // 2. HEADER TOKO
    bytes.addAll(_buildHeader(generator, config));

    // 3. Posisi Logo: AFTER_HEADER
    insertLogoIfPosition(ReceiptLogoPosition.afterHeader);

    // 4. INFORMASI TRANSAKSI
    bytes.addAll(_buildInvoiceInfo(generator, invoice, config, divider));

    // 5. Posisi Logo: BEFORE_ITEMS
    insertLogoIfPosition(ReceiptLogoPosition.beforeItems);

    // 6. DAFTAR BARANG
    bytes.addAll(_buildItemsList(generator, items, numFormat, config, divider));

    // 7. TOTAL & PEMBAYARAN
    bytes.addAll(_buildTotalSection(
      generator,
      total,
      rpFormat,
      config,
      divider,
      cashPaid ?? total,
      change ?? 0,
    ));

    // 8. Posisi Logo: AFTER_TOTAL
    insertLogoIfPosition(ReceiptLogoPosition.afterTotal);

    // 9. FOOTER & QR CODE
    bytes.addAll(_buildFooter(generator, config, invoice));

    // 10. Posisi Logo: BOTTOM (Paling Bawah)
    insertLogoIfPosition(ReceiptLogoPosition.bottom);

    // Dorong kertas 3 baris lalu potong
    bytes.addAll(generator.feed(3));
    bytes.addAll(generator.cut());

    return bytes;
  }

  // --- COMPONENT BUILDERS ---

  List<int> _buildHeader(Generator generator, ReceiptCustomModel config) {
    final bytes = <int>[];

    PosTextSize heightSize = PosTextSize.size2;
    PosTextSize widthSize = PosTextSize.size2;
    if (config.storeNameSize == 'normal') {
      heightSize = PosTextSize.size1;
      widthSize = PosTextSize.size1;
    } else if (config.storeNameSize == 'extra_large') {
      heightSize = PosTextSize.size3;
      widthSize = PosTextSize.size3;
    }

    bytes.addAll(
      generator.text(
        config.storeName,
        styles: PosStyles(
          align: PosAlign.center,
          bold: true,
          height: heightSize,
          width: widthSize,
          fontType: PosFontType.fontA,
        ),
      ),
    );

    if (config.showHeaderNote && config.headerNote.isNotEmpty) {
      bytes.addAll(
        generator.text(
          config.headerNote,
          styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontA),
        ),
      );
    }

    if (config.showAddress && config.storeAddress.isNotEmpty) {
      bytes.addAll(
        generator.text(
          config.storeAddress,
          styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontA),
        ),
      );
    }

    if (config.showContact && config.storeContact.isNotEmpty) {
      bytes.addAll(
        generator.text(
          config.storeContact,
          styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontA),
        ),
      );
    }

    return bytes;
  }

  List<int> _buildInvoiceInfo(
    Generator generator,
    String invoice,
    ReceiptCustomModel config,
    String divider,
  ) {
    final bytes = <int>[];

    bytes.addAll(
      generator.text(
        divider,
        styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontA),
      ),
    );

    if (config.showInvoiceNumber) {
      bytes.addAll(
        generator.text(
          'No  : $invoice',
          styles: const PosStyles(fontType: PosFontType.fontA),
        ),
      );
    }

    if (config.showDate || config.showTime) {
      String datePattern = 'dd-MM-yyyy';
      if (config.showDate && config.showTime) {
        datePattern = 'dd-MM-yyyy HH:mm';
      } else if (config.showTime) {
        datePattern = 'HH:mm:ss';
      }
      bytes.addAll(
        generator.text(
          'Tgl : ${DateFormat(datePattern).format(DateTime.now())}',
          styles: const PosStyles(fontType: PosFontType.fontA),
        ),
      );
    }

    if (config.showCashierName && config.cashierName.isNotEmpty) {
      bytes.addAll(
        generator.text(
          'Ksr : ${config.cashierName}',
          styles: const PosStyles(fontType: PosFontType.fontA),
        ),
      );
    }

    bytes.addAll(
      generator.text(
        divider,
        styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontA),
      ),
    );
    return bytes;
  }

  List<int> _buildItemsList(
    Generator generator,
    List<CartItem> items,
    NumberFormat numFormat,
    ReceiptCustomModel config,
    String divider,
  ) {
    final bytes = <int>[];

    for (final item in items) {
      if (config.compactItemRows) {
        bytes.addAll(
          generator.row([
            PosColumn(
              text: '${item.qty}x ${item.product.name.toUpperCase()}',
              width: 8,
              styles: const PosStyles(bold: true, fontType: PosFontType.fontA),
            ),
            PosColumn(
              text: numFormat.format(item.qty * item.product.price),
              width: 4,
              styles: const PosStyles(align: PosAlign.right, fontType: PosFontType.fontA),
            ),
          ]),
        );
      } else {
        bytes.addAll(
          generator.text(
            item.product.name.toUpperCase(),
            styles: const PosStyles(bold: true, fontType: PosFontType.fontA),
          ),
        );
        bytes.addAll(
          generator.row([
            PosColumn(
              text: '${item.qty} x ${numFormat.format(item.product.price)}',
              width: 7,
              styles: const PosStyles(fontType: PosFontType.fontA),
            ),
            PosColumn(
              text: numFormat.format(item.qty * item.product.price),
              width: 5,
              styles: const PosStyles(align: PosAlign.right, fontType: PosFontType.fontA),
            ),
          ]),
        );
      }
    }

    bytes.addAll(
      generator.text(
        divider,
        styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontA),
      ),
    );
    return bytes;
  }

  List<int> _buildTotalSection(
    Generator generator,
    int total,
    NumberFormat rpFormat,
    ReceiptCustomModel config,
    String divider,
    int cashPaid,
    int change,
  ) {
    final bytes = <int>[];

    if (config.showSubtotalRow && config.showTax) {
      final subtotal = (total / (1 + (config.taxPercent / 100))).round();
      bytes.addAll(
        generator.row([
          PosColumn(text: 'Subtotal', width: 6, styles: const PosStyles(fontType: PosFontType.fontA)),
          PosColumn(text: rpFormat.format(subtotal), width: 6, styles: const PosStyles(align: PosAlign.right, fontType: PosFontType.fontA)),
        ]),
      );
      final taxAmt = total - subtotal;
      bytes.addAll(
        generator.row([
          PosColumn(text: 'PPN (${config.taxPercent.toStringAsFixed(0)}%)', width: 6, styles: const PosStyles(fontType: PosFontType.fontA)),
          PosColumn(text: rpFormat.format(taxAmt), width: 6, styles: const PosStyles(align: PosAlign.right, fontType: PosFontType.fontA)),
        ]),
      );
    }

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

    if (config.showCashAndChange && cashPaid > 0) {
      bytes.addAll(
        generator.row([
          PosColumn(text: 'Tunai', width: 6, styles: const PosStyles(fontType: PosFontType.fontA)),
          PosColumn(text: rpFormat.format(cashPaid), width: 6, styles: const PosStyles(align: PosAlign.right, fontType: PosFontType.fontA)),
        ]),
      );
      if (change >= 0) {
        bytes.addAll(
          generator.row([
            PosColumn(text: 'Kembali', width: 6, styles: const PosStyles(fontType: PosFontType.fontA)),
            PosColumn(text: rpFormat.format(change), width: 6, styles: const PosStyles(align: PosAlign.right, fontType: PosFontType.fontA)),
          ]),
        );
      }
    }

    bytes.addAll(
      generator.text(
        divider,
        styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontA),
      ),
    );
    return bytes;
  }

  List<int> _buildFooter(
    Generator generator,
    ReceiptCustomModel config,
    String invoice,
  ) {
    final bytes = <int>[];

    if (config.showFooterMessage && config.footerMessage.isNotEmpty) {
      bytes.addAll(
        generator.text(
          config.footerMessage,
          styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontA),
        ),
      );
    }

    if (config.showSocialMedia && config.socialMediaText.isNotEmpty) {
      bytes.addAll(
        generator.text(
          config.socialMediaText,
          styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontA),
        ),
      );
    }

    if (config.showWarrantyNotice && config.warrantyNotice.isNotEmpty) {
      bytes.addAll(generator.feed(1));
      bytes.addAll(
        generator.text(
          'KETENTUAN:',
          styles: const PosStyles(align: PosAlign.center, bold: true, fontType: PosFontType.fontA),
        ),
      );
      bytes.addAll(
        generator.text(
          config.warrantyNotice,
          styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontA),
        ),
      );
    }

    if (config.showInvoiceQr) {
      bytes.addAll(generator.feed(1));
      bytes.addAll(generator.qrcode(invoice, align: PosAlign.center));
    }

    return bytes;
  }
}
