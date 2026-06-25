import 'package:flutter/material.dart';
import '../services/local_db_service.dart';
import '../services/category_service.dart';
import '../models/product_model.dart';

class AddProductController extends ChangeNotifier {
  final LocalDbService _db = LocalDbService.instance;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController stockController = TextEditingController();

  String? scannedBarcode;
  bool isLoading = false;

  List<String> categories = [];
  String selectedCategory = 'Umum';

  AddProductController() {
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    categories = await CategoryService.getCategories();
    if (!categories.any(
      (c) => c.toLowerCase() == selectedCategory.toLowerCase(),
    )) {
      if (categories.isNotEmpty) {
        selectedCategory = categories.first;
      }
    }
    notifyListeners();
  }

  Future<bool> addCategory(String newCategory) async {
    final success = await CategoryService.addCategory(newCategory);
    if (success) {
      await _loadCategories();
    }
    return success;
  }

  void setCategory(String? value) {
    if (value != null) {
      selectedCategory = value;
      notifyListeners();
    }
  }

  void setScannedCode(String code) {
    scannedBarcode = code;
    notifyListeners();
  }

  void resetScan() {
    scannedBarcode = null;
    notifyListeners();
  }

  Future<List<Product>> searchProducts(String query) async {
    if (query.trim().isEmpty) return [];
    return await _db.searchProducts(query);
  }

  void fillFormFromExisting(Product product) {
    nameController.text = product.name;
    priceController.text = product.price.toString();
    stockController.text = product.stock.toString();
    selectedCategory = categories.firstWhere(
      (c) => c.toLowerCase() == (product.category).toLowerCase(),
      orElse: () => categories.first,
    );
    notifyListeners();
  }

  Future<Product?> saveProduct(BuildContext context) async {
    final name = nameController.text.trim();
    final priceText = priceController.text.trim();
    final stockText = stockController.text.trim();

    if (name.isEmpty || priceText.isEmpty || stockText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Harap isi semua kolom!')));
      return null;
    }

    final price = int.tryParse(priceText.replaceAll(RegExp(r'[^0-9]'), ''));
    final stock = int.tryParse(stockText.replaceAll(RegExp(r'[^0-9]'), ''));
    if (price == null || stock == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harga dan stok harus angka!')),
      );
      return null;
    }

    // Cek duplikasi kode jika menggunakan barcode
    if (scannedBarcode != null && scannedBarcode!.isNotEmpty) {
      final existingProduct = await _db.getProductByCode(scannedBarcode!);
      if (existingProduct != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Kode "${scannedBarcode}" sudah digunakan oleh produk "${existingProduct.name}".',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return null;
      }
    }

    isLoading = true;
    notifyListeners();

    try {
      final product = await _db.addProduct(
        name,
        price,
        stock,
        selectedCategory,
        code: scannedBarcode,
      );

      // Reset form
      nameController.clear();
      priceController.clear();
      stockController.clear();
      scannedBarcode = null;

      return product;
    } catch (e) {
      debugPrint('Error saving product: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    super.dispose();
  }
}
