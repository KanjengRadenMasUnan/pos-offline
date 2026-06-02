import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import '../providers/cart_provider.dart';
import '../services/local_db_service.dart'; // Diubah ke local_db_service
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

  // --- Scanner State (NEW FEATURES) ---
  bool isScanning = false; // Indikator loading saat scan
  DateTime? _lastScanTime; // Penampung waktu scan terakhir

  // ==========================================================
  // PRODUCT LOGIC
  // ==========================================================

  Future<void> fetchProductList() async {
    try {
      // Mengambil daftar produk dari database lokal offline
      _allProducts = await LocalDbService.instance.getAllProducts();
      notifyListeners();
    } catch (error) {
      debugPrint('Error load produk: $error');
    }
  }

  void searchProducts(String query) {
    if (query.isEmpty) {
      _searchResults = [];
    } else {
      _searchResults = _allProducts
          .where(
            (product) =>
                product.name.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  // ==========================================================
  // CART & SCAN LOGIC
  // ==========================================================

  void addToCartFromSearch(Product product, CartProvider cart) {
    final currentQty = _getCurrentQuantityInCart(product.id, cart);

    if (currentQty < product.stock) {
      cart.addToCart(product);
      _showSuccessMessage('✅ ${product.name} (+1)');
    } else {
      _showWarningMessage('Stok tidak cukup!');
    }
  }

  Future<void> handleScannedBarcodeWithDelay(
    String rawCode,
    CartProvider cartProvider,
  ) async {
    final now = DateTime.now();

    if (_lastScanTime != null) {
      final difference = now.difference(_lastScanTime!);
      if (difference.inSeconds < 2) return;
    }
    _lastScanTime = now;
    isScanning = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    await handleScannedCode(rawCode, cartProvider);
    isScanning = false;
    notifyListeners();
  }

  Future<void> handleScannedCode(
    String rawCode,
    CartProvider cartProvider,
  ) async {
    SoundService.playBeep();

    final codeToSend = _processRawBarcode(rawCode);
    final localProduct = _findLocalProduct(codeToSend);

    if (localProduct != null) {
      addToCartFromSearch(localProduct, cartProvider);
      return;
    }

    await _searchProductFromApi(codeToSend, cartProvider);
  }

  // ==========================================================
  // TRANSACTION LOGIC
  // ==========================================================

  Future<String?> processCheckout(CartProvider cart) async {
    if (withStruk && !isPrinterConnected) {
      _showWarningMessage(
        'Printer belum konek! Matikan opsi struk atau hubungkan.',
      );
      return null;
    }

    // Melakukan proses checkout transaksi dan potong stok langsung di SQLite lokal
    final invoice = await LocalDbService.instance.checkout(
      cart.items,
      cart.totalAmount,
    );

    if (invoice != null) {
      await _handleSuccessfulCheckout(invoice, cart);
      return invoice;
    }

    _showErrorMessage('Gagal transaksi lokal');
    return null;
  }

  // ==========================================================
  // PRINTER LOGIC
  // ==========================================================

  void initPrinter() async {
    isPrinterLoading = true;
    notifyListeners();

    final isConnected = await _printerService.checkConnection();
    if (isConnected) {
      devices = await _printerService.getPairedDevices();
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

    _showInfoMessage('Sedang mencetak...');
    await _printerService.printStruk(invoice, items, total);
  }

  void toggleStrukOption(bool value) {
    withStruk = value;
    notifyListeners();
  }

  // ==========================================================
  // PRIVATE HELPER METHODS
  // ==========================================================

  int _getCurrentQuantityInCart(int productId, CartProvider cart) {
    final index = cart.items.indexWhere((item) => item.product.id == productId);
    return index != -1 ? cart.items[index].qty : 0;
  }

  String _processRawBarcode(String rawCode) {
    try {
      if (rawCode.length > 15 || rawCode.contains('=')) {
        final decrypted = SecurityService.decryptData(rawCode);
        return decrypted.isNotEmpty ? decrypted : rawCode;
      }
    } catch (error) {
      debugPrint('Error decrypting barcode: $error');
    }
    return rawCode;
  }

  Product? _findLocalProduct(String code) {
    try {
      return _allProducts.firstWhere((product) => product.code == code);
    } catch (_) {
      return null;
    }
  }

  Future<void> _searchProductFromApi(
    String code,
    CartProvider cartProvider,
  ) async {
    _showInfoMessage('Mencari barang...');
    // Dialihkan untuk mencari kode barang di database lokal offline jika tidak ada di memory list
    final product = await LocalDbService.instance.getProductByCode(code);

    if (product != null) {
      addToCartFromSearch(product, cartProvider);
    } else {
      _showErrorMessage('Barang tidak ditemukan!');
    }
  }

  Future<void> _handleSuccessfulCheckout(
    String invoice,
    CartProvider cart,
  ) async {
    final transactionItems = List<CartItem>.from(cart.items);
    final transactionTotal = cart.totalAmount;

    if (onShowTransactionSuccess != null) {
      onShowTransactionSuccess!(invoice, transactionItems, transactionTotal);
    }
    if (withStruk) {
      _printerService
          .printStruk(invoice, transactionItems, transactionTotal)
          .then((_) => print("Print background sukses"))
          .catchError((e) => print("Print background gagal: $e"));
    }

    fetchProductList();
    cart.clearCart();
  }

  void _showSuccessMessage(String message) =>
      onShowMessage?.call(message, Colors.green);
  void _showWarningMessage(String message) =>
      onShowMessage?.call(message, Colors.orange);
  void _showErrorMessage(String message) =>
      onShowMessage?.call(message, Colors.red);
  void _showInfoMessage(String message) =>
      onShowMessage?.call(message, Colors.blue);
}
