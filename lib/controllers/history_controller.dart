import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../models/transaction_model.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import '../services/local_db_service.dart'; // <-- Tambahkan import ini
import '../services/printer_service.dart';

class HistoryController extends ChangeNotifier {
  // HAPUS: final ApiService _api = ApiService(); karena tidak digunakan lagi

  final LocalDbService _db =
      LocalDbService.instance; // <-- Gunakan LocalDbService

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
    // ... (tidak ada perubahan di sini, sama seperti sebelumnya)
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

      final List<CartItem> cartItems = transaction.items.map((item) {
        final product = Product(
          id: item.productId,
          name: item.productName,
          price: item.price,
          stock: 0,
          code: '',
          category: '',
        );
        return CartItem(product: product, qty: item.qty);
      }).toList();

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

  // --- GANTI loadHistory() INI DARI API MENJADI LOCAL DB ---
  Future<void> loadHistory() async {
    isLoading = true;
    notifyListeners();

    try {
      // Panggil local database, bukan API
      transactions = await _db.getTransactionHistory(
        startDate: selectedDateRange?.start,
        endDate: selectedDateRange?.end,
      );
    } catch (e) {
      debugPrint('Error loading history: $e');
      // Jika error, kosongkan transaksi
      transactions = [];
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
