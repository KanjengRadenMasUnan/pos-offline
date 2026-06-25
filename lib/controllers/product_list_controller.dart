import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import '../services/excel_service.dart';
import 'package:share_plus/share_plus.dart';
import '../models/product_model.dart';
import '../services/local_db_service.dart';
import '../services/category_service.dart'; // <-- tambahan

class ProductListController extends ChangeNotifier {
  final ExcelService _excelService = ExcelService();

  // --- Controllers & Form State ---
  final TextEditingController nameEditCtrl = TextEditingController();
  final TextEditingController priceEditCtrl = TextEditingController();
  final TextEditingController stockEditCtrl = TextEditingController();
  String selectedEditCategory = 'Umum';

  // --- Product State ---
  List<Product> _allProducts = [];
  List<Product> products = [];
  bool isLoading = true;
  bool isExporting = false;

  // --- Filter & Sort State ---
  String searchQuery = '';
  String selectedCategory = 'Semua';
  String _currentSort = 'name_asc';

  // Kategori dinamis (dari service)
  List<String> _allCategories = [];

  // --- Getters ---
  List<String> get filterCategories => ['Semua', ..._allCategories];
  String get currentSort => _currentSort;

  ProductListController() {
    fetchProducts();
    _loadCategories();
  }

  // --- Load kategori dari SharedPreferences ---
  Future<void> _loadCategories() async {
    _allCategories = await CategoryService.getCategories();
    notifyListeners();
  }

  // --- Main Data Methods (CRUD) ---
  Future<void> fetchProducts() async {
    isLoading = true;
    notifyListeners();

    try {
      _allProducts = await LocalDbService.instance.getAllProducts();
      _applyFilters();
    } catch (error) {
      debugPrint('Error loading products: $error');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void loadProducts() => fetchProducts();

  Future<bool> saveEdit(int id) async {
    try {
      final price = _parseNumber(priceEditCtrl.text);
      final stock = _parseNumber(stockEditCtrl.text);

      final success = await LocalDbService.instance.updateProduct(
        id,
        nameEditCtrl.text,
        price,
        stock,
        selectedEditCategory,
      );

      if (success) await fetchProducts();
      return success;
    } catch (error) {
      debugPrint('Error saving edit: $error');
      return false;
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      final success = await LocalDbService.instance.deleteProduct(id);
      if (success) {
        _allProducts.removeWhere((product) => product.id == id);
        _applyFilters();
      }
      return success;
    } catch (error) {
      debugPrint('Error deleting product: $error');
      return false;
    }
  }

  Future<void> exportStokKeExcel() async {
    if (products.isEmpty) return;

    isExporting = true;
    notifyListeners();

    try {
      final path = await _excelService.exportProductToExcel(_allProducts);

      if (path != null) {
        await Share.shareXFiles([
          XFile(path),
        ], text: 'Laporan Stok Nanda Cell - ${DateTime.now()}');
      }
    } catch (e) {
      debugPrint('Gagal export excel: $e');
    } finally {
      isExporting = false;
      notifyListeners();
    }
  }

  Future<void> importProductsFromExcel(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null || result.files.single.path == null) return;

      isLoading = true;
      notifyListeners();

      var bytes = File(result.files.single.path!).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      int jumlahSukses = 0;

      for (var table in excel.tables.keys) {
        var rows = excel.tables[table]!.rows;

        for (int i = 1; i < rows.length; i++) {
          var row = rows[i];
          if (row.isEmpty || row.length < 3) continue;

          String code = row[1]?.value?.toString().trim() ?? '';
          String name = row[2]?.value?.toString().trim() ?? '';
          if (name.isEmpty) continue;

          String categoryRaw = row[3]?.value?.toString().trim() ?? 'Umum';
          // Sesuaikan dengan kategori yang ada (case-insensitive)
          String category = _allCategories.firstWhere(
            (cat) => cat.toLowerCase() == categoryRaw.toLowerCase(),
            orElse: () => 'Umum',
          );

          int price =
              int.tryParse(
                row[4]?.value?.toString().replaceAll(RegExp(r'[^0-9]'), '') ??
                    '0',
              ) ??
              0;
          int stock =
              int.tryParse(
                row[5]?.value?.toString().replaceAll(RegExp(r'[^0-9]'), '') ??
                    '0',
              ) ??
              0;

          await LocalDbService.instance.addProduct(
            name,
            price,
            stock,
            category,
            code: code.isEmpty ? null : code,
          );

          jumlahSukses++;
        }
      }

      await fetchProducts();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Berhasil mengimpor $jumlahSukses produk dari Excel!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error Import Excel: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '❌ Gagal mengimpor data Excel. Periksa kembali struktur file Anda.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- UI Action Methods ---
  void setSearch(String query) {
    searchQuery = query;
    _applyFilters();
  }

  void searchProduct(String query) => setSearch(query);

  void setCategory(String category) {
    selectedCategory = category;
    _applyFilters();
  }

  void sortProducts(String sortType) {
    _currentSort = sortType;
    _applyFilters();
  }

  void prepareEdit(Product product) {
    nameEditCtrl.text = product.name;
    priceEditCtrl.text = product.price.toString();
    stockEditCtrl.text = product.stock.toString();

    final incomingCategory = (product.category ?? 'Umum').trim();
    selectedEditCategory = _allCategories.firstWhere(
      (c) => c.toLowerCase() == incomingCategory.toLowerCase(),
      orElse: () => _allCategories.isNotEmpty ? _allCategories.first : 'Umum',
    );
  }

  // --- Logic Processing (Private) ---
  void _applyFilters() {
    final filtered = _filterProducts();
    products = _sortProducts(filtered);
    notifyListeners();
  }

  List<Product> _filterProducts() {
    return _allProducts.where((product) {
      final matchesName = product.name.toLowerCase().contains(
        searchQuery.toLowerCase(),
      );
      final matchesCategory =
          selectedCategory == 'Semua' ||
          product.category.toLowerCase() == selectedCategory.toLowerCase();
      return matchesName && matchesCategory;
    }).toList();
  }

  List<Product> _sortProducts(List<Product> productsToSort) {
    switch (_currentSort) {
      case 'name_asc':
        productsToSort.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case 'name_desc':
        productsToSort.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
        break;
      case 'price_asc':
        productsToSort.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        productsToSort.sort((a, b) => b.price.compareTo(a.price));
        break;
    }
    return productsToSort;
  }

  int _parseNumber(String text) {
    return int.parse(text.replaceAll('.', '').replaceAll(',', ''));
  }

  // --- PERBAIKAN UTAMA: Menggunakan Sistem Lifecycle Otomatis ---
  @override
  void dispose() {
    nameEditCtrl.dispose();
    priceEditCtrl.dispose();
    stockEditCtrl.dispose();
    super.dispose();
  }
}
