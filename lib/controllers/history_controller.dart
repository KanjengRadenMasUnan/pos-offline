import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../models/transaction_model.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import '../services/api_service.dart';
import '../services/printer_service.dart';

class HistoryController extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<BluetoothInfo> devices = [];
  BluetoothInfo? selectedDevice;
  bool isPrinterConnected = false;
  bool isPrinterLoading = false;
  final PrinterService _printerService = PrinterService();

  // --- State Variables ---
  List<TransactionModel> transactions = [];
  bool isLoading = true;
  DateTimeRange? selectedDateRange;

  Function(String message, Color color)? onShowMessage;

  void initPrinter() async {
    isPrinterLoading = true;
    notifyListeners();

    final isEnabled = await PrintBluetoothThermal.bluetoothEnabled;
    if (isEnabled) {
      devices = await PrintBluetoothThermal.pairedBluetooths;
    }
    isPrinterConnected = await PrintBluetoothThermal.connectionStatus;

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

  // --- Getters ---
  String get filterStatusText {
    if (selectedDateRange == null) {
      return 'Menampilkan 50 Transaksi Terakhir';
    }

    final start = _formatDate(selectedDateRange!.start);
    final end = _formatDate(selectedDateRange!.end);

    return 'Filter: $start - $end';
  }

  Future<void> reprintTransaction(TransactionModel transaction) async {
    // 1. Cek koneksi printer
    final isConnected = await PrintBluetoothThermal.connectionStatus;
    if (!isConnected) {
      onShowMessage?.call(
        'Printer belum terhubung! Buka pengaturan untuk menghubungkan.',
        Colors.red,
      );
      return;
    }

    try {
      onShowMessage?.call(
        'Mencetak ulang struk ${transaction.invoiceNumber}...',
        Colors.blue,
      );

      // 2. Konversi TransactionItemModel -> CartItem
      final List<CartItem> cartItems = transaction.items.map((item) {
        // Buat Product model dari data item
        final product = Product(
          id: item.productId,
          name: item.productName,
          price: item.price,
          stock: 0, // Tidak diperlukan untuk cetak
          code: '', // Tidak diperlukan untuk cetak
          category: '', // Tidak diperlukan untuk cetak
        );
        return CartItem(product: product, qty: item.qty);
      }).toList();

      // 3. Panggil PrinterService (sama persis seperti di kasir)
      await _printerService.printStruk(
        transaction.invoiceNumber,
        cartItems,
        transaction.totalAmount,
      );

      onShowMessage?.call('Struk berhasil dicetak ulang!', Colors.green);
    } catch (e) {
      onShowMessage?.call('Gagal mencetak: $e', Colors.red);
    }
  }

  Future<void> loadHistory() async {
    isLoading = true;
    notifyListeners();

    try {
      transactions = await _api.getTransactionHistory(
        startDate: selectedDateRange?.start,
        endDate: selectedDateRange?.end,
      );
    } catch (e) {
      debugPrint('Error loading history: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- Filter Management ---

  void applyDateFilter(DateTimeRange range) {
    selectedDateRange = range;
    loadHistory();
  }

  void resetFilter() {
    selectedDateRange = null;
    loadHistory();
  }

  // --- Private Helpers ---

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}
