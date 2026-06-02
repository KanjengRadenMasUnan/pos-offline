import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/local_db_service.dart'; // Diubah ke local_db_service
import '../services/sound_service.dart';

class AddProductController extends ChangeNotifier {
  // --- Controllers ---
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController codeController = TextEditingController();

  // --- State Variables ---
  bool isLoading = false;
  String selectedCategory = 'Umum';

  final List<String> categories = [
    'Umum',
    'Kabel Data',
    'Powerbank',
    'Memory',
    'Charger',
    'Batok',
    'Headset',
    'Casing',
    'Kartu Perdana',
    'Tempered Glass',
    'Voucher',
    'Service',
  ];

  // --- Getters ---
  String? get scannedBarcode {
    final value = codeController.text.trim();
    return value.isEmpty ? null : value;
  }

  // --- Public Methods (Logic) ---
  void setCategory(String? newVal) {
    if (newVal == null) return;
    selectedCategory = newVal;
    notifyListeners();
  }

  Future<Product?> saveProduct(BuildContext context) async {
    if (nameController.text.isEmpty || priceController.text.isEmpty) {
      _showValidationError(context);
      return null;
    }

    isLoading = true;
    notifyListeners();

    try {
      final product = await _createAndSendProduct();

      isLoading = false;
      notifyListeners();

      if (product != null) {
        _clearForm();
        return product;
      }

      return null;
    } catch (e) {
      _handleError(context, e);
      return null;
    }
  }

  void fillFormFromExisting(Product product) {
    nameController.text = product.name;
    priceController.text = product.price.toString();
    stockController.text = product.stock.toString();
    codeController.text = product.code;

    _setCategoryFromProduct(product);
    notifyListeners();
  }

  void setScannedCode(String code) {
    codeController.text = code;
    SoundService.playBeep();
    notifyListeners();
  }

  void resetScan() {
    codeController.clear();
    notifyListeners();
  }

  Future<List<Product>> searchProducts(String query) {
    // Diarahkan langsung ke query database offline lokal
    return LocalDbService.instance.searchProducts(query);
  }

  // --- Private Helper Methods ---
  Future<Product?> _createAndSendProduct() async {
    final harga = int.parse(priceController.text.replaceAll('.', ''));
    final stok = stockController.text.isEmpty
        ? 0
        : int.parse(stockController.text.replaceAll('.', ''));

    final kodeKirim = codeController.text.trim().isEmpty
        ? null
        : codeController.text.trim();

    // Diarahkan untuk melakukan proses insert ke SQLite lokal
    return LocalDbService.instance.addProduct(
      nameController.text,
      harga,
      stok,
      selectedCategory,
      code: kodeKirim,
    );
  }

  void _setCategoryFromProduct(Product product) {
    final incoming = product.category.trim().toLowerCase();

    try {
      selectedCategory = categories.firstWhere(
        (cat) =>
            cat.toLowerCase() == incoming ||
            incoming.contains(cat.toLowerCase()),
      );
    } catch (_) {
      selectedCategory = 'Umum';
    }
  }

  void _clearForm() {
    nameController.clear();
    priceController.clear();
    stockController.clear();
    codeController.clear();
    selectedCategory = 'Umum';
    notifyListeners();
  }

  void _showValidationError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nama dan Harga wajib diisi!'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleError(BuildContext context, Object error) {
    isLoading = false;
    notifyListeners();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gagal: ${error.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    codeController.dispose();
    super.dispose();
  }
}
