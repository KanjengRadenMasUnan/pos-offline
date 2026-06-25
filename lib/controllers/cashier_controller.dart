import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import '../providers/cart_provider.dart';
import '../services/local_db_service.dart';
import '../services/printer_service.dart';
import '../services/security_service.dart';
import '../services/sound_service.dart';

class CashierController extends ChangeNotifier {
  final PrinterService _printerService = PrinterService();

  // --- Callbacks (UI Listeners) ---
  Function(String message, Color color)? onShowMessage;
  Function(String invoice, List<CartItem> items, int total)?
  onShowTransactionSuccess;

  // --- Product & Search State ---
  List<Product> _allProducts = [];
  List<Product> _searchResults = [];

  List<Product> get allProducts => _allProducts;
  List<Product> get searchResults => _searchResults;

  // --- Printer & Hardware State ---
  List<BluetoothInfo> devices = [];
  BluetoothInfo? selectedDevice;
  bool isPrinterConnected = false;
  bool isPrinterLoading = false;
  bool withStruk = true;

  // --- Scanner State ---
  bool isScanning = false;
  DateTime? _lastScanTime;

  // --- Payment State ---
  int _cashReceived = 0;
  int get cashReceived => _cashReceived;

  void updateCashReceived(String value) {
    final cleanedValue = value.replaceAll('.', '').replaceAll(',', '').trim();
    _cashReceived = int.tryParse(cleanedValue) ?? 0;
    notifyListeners();
  }

  void setCashReceived(int amount) {
    _cashReceived = amount;
    notifyListeners();
  }

  void clearPayment() {
    _cashReceived = 0;
    notifyListeners();
  }

  int calculateChange(int totalAmount) {
    if (_cashReceived <= totalAmount) return 0;
    return _cashReceived - totalAmount;
  }

  bool isPaymentSufficient(int totalAmount) {
    return _cashReceived >= totalAmount;
  }

  // ==========================================================
  // PRODUCT LOGIC (OFFLINE OPTIMIZED)
  // ==========================================================

  /// Ambil semua produk dari database lokal
  Future<void> fetchProductList() async {
    try {
      _allProducts = await LocalDbService.instance.getAllProducts();
      notifyListeners();
    } catch (error) {
      debugPrint('Error load produk: $error');
      _allProducts = [];
      notifyListeners();
    }
  }

  /// Pencarian produk menggunakan database lokal (LIKE name & code)
  Future<void> searchProducts(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      // Gunakan service database yang sudah mendukung pencarian via name dan code
      _searchResults = await LocalDbService.instance.searchProducts(
        query.trim(),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error search products: $e');
      _searchResults = [];
      notifyListeners();
    }
  }

  /// Hapus hasil pencarian
  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  // ==========================================================
  // CART & SCAN LOGIC
  // ==========================================================

  /// Tambahkan produk ke keranjang dari hasil pencarian
  void addToCartFromSearch(Product product, CartProvider cart) {
    final currentQty = _getCurrentQuantityInCart(product.id, cart);
    if (currentQty < product.stock) {
      cart.addToCart(product);
      _showSuccessMessage('✅ ${product.name} (+1)');
    } else {
      _showWarningMessage('Stok tidak cukup!');
    }
  }

  /// Handle hasil scan barcode (dengan debounce sederhana)
  Future<void> handleScannedBarcodeWithDelay(
    String rawCode,
    CartProvider cartProvider,
  ) async {
    // Debounce 1.5 detik untuk mencegah double scan
    final now = DateTime.now();
    if (_lastScanTime != null &&
        now.difference(_lastScanTime!).inMilliseconds < 1500)
      return;
    _lastScanTime = now;

    isScanning = true;
    notifyListeners();

    await Future.delayed(
      const Duration(milliseconds: 300),
    ); // sedikit delay untuk feedback UI
    await handleScannedCode(rawCode, cartProvider);

    isScanning = false;
    notifyListeners();
  }

  /// Proses kode barcode mentah
  Future<void> handleScannedCode(
    String rawCode,
    CartProvider cartProvider,
  ) async {
    SoundService.playBeep();

    final codeToFind = _processRawBarcode(rawCode);

    // 1. Cari di list yang sudah di-fetch (lebih cepat)
    Product? product = _findLocalProduct(codeToFind);

    // 2. Jika tidak ada, cari langsung ke database
    product ??= await LocalDbService.instance.getProductByCode(codeToFind);

    if (product != null) {
      addToCartFromSearch(product, cartProvider);
    } else {
      _showErrorMessage('Barang dengan kode "$codeToFind" tidak ditemukan');
    }
  }

  // ==========================================================
  // TRANSACTION LOGIC
  // ==========================================================

  Future<String?> processCheckout(CartProvider cart) async {
    if (cart.items.isEmpty) {
      _showWarningMessage('Keranjang masih kosong!');
      return null;
    }

    if (withStruk && !isPrinterConnected) {
      _showWarningMessage(
        'Printer belum terhubung! Matikan opsi struk atau hubungkan printer.',
      );
      return null;
    }

    if (!isPaymentSufficient(cart.totalAmount)) {
      _showWarningMessage('Uang pelanggan kurang!');
      return null;
    }

    final invoice = await LocalDbService.instance.checkout(
      cart.items,
      cart.totalAmount,
    );

    if (invoice != null) {
      await _handleSuccessfulCheckout(invoice, cart);
      return invoice;
    } else {
      _showErrorMessage('Gagal menyimpan transaksi lokal');
      return null;
    }
  }

  // ==========================================================
  // PRINTER LOGIC
  // ==========================================================

  void initPrinter() async {
    isPrinterLoading = true;
    notifyListeners();
    try {
      final isEnabled = await PrintBluetoothThermal.bluetoothEnabled;
      if (isEnabled) {
        devices = await PrintBluetoothThermal.pairedBluetooths;
      }
      isPrinterConnected = await PrintBluetoothThermal.connectionStatus;
    } catch (e) {
      debugPrint('Error init printer: $e');
    }
    isPrinterLoading = false;
    notifyListeners();
  }

  Future<void> connectPrinter(BluetoothInfo device) async {
    isPrinterLoading = true;
    notifyListeners();

    bool connected = await _printerService.connect(device.macAdress);
    if (!connected) {
      connected = await PrintBluetoothThermal.connectionStatus;
    }

    if (connected) {
      selectedDevice = device;
      isPrinterConnected = true;
    } else {
      _showErrorMessage('Gagal terhubung ke printer');
    }

    isPrinterLoading = false;
    notifyListeners();
  }

  Future<void> printReceipt(
    String invoice,
    List<CartItem> items,
    int total,
  ) async {
    if (!isPrinterConnected) {
      _showWarningMessage('Printer belum terhubung!');
      return;
    }
    _showInfoMessage('Mencetak struk...');
    await _printerService.printStruk(invoice, items, total);
  }

  void toggleStrukOption(bool value) {
    withStruk = value;
    notifyListeners();
  }

  // ==========================================================
  // PRIVATE HELPERS
  // ==========================================================

  int _getCurrentQuantityInCart(int productId, CartProvider cart) {
    final index = cart.items.indexWhere((item) => item.product.id == productId);
    return index != -1 ? cart.items[index].qty : 0;
  }

  String _processRawBarcode(String rawCode) {
    try {
      // Jika panjang > 15 atau mengandung '=', coba dekripsi
      if (rawCode.length > 15 || rawCode.contains('=')) {
        final decrypted = SecurityService.decryptData(rawCode);
        if (decrypted.isNotEmpty && decrypted != rawCode) {
          return decrypted;
        }
      }
    } catch (e) {
      debugPrint('Decrypt error: $e');
    }
    return rawCode.trim();
  }

  Product? _findLocalProduct(String code) {
    try {
      return _allProducts.firstWhere((p) => p.code == code);
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleSuccessfulCheckout(
    String invoice,
    CartProvider cart,
  ) async {
    final transactionItems = List<CartItem>.from(cart.items);
    final transactionTotal = cart.totalAmount;

    // Panggil callback sukses
    onShowTransactionSuccess?.call(invoice, transactionItems, transactionTotal);

    // Cetak struk (background)
    if (withStruk) {
      _printerService
          .printStruk(invoice, transactionItems, transactionTotal)
          .then((_) => print("Cetak struk berhasil"))
          .catchError((e) => print("Gagal cetak struk: $e"));
    }

    // Refresh daftar produk (karena stok berubah)
    await fetchProductList();
    clearPayment();
    cart.clearCart();
  }

  // --- Feedback helpers ---
  void _showSuccessMessage(String msg) =>
      onShowMessage?.call(msg, Colors.green);
  void _showWarningMessage(String msg) =>
      onShowMessage?.call(msg, Colors.orange);
  void _showErrorMessage(String msg) => onShowMessage?.call(msg, Colors.red);
  void _showInfoMessage(String msg) => onShowMessage?.call(msg, Colors.blue);
}
