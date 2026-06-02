import 'dart:io'; // Ditambahkan untuk penanganan file lokal
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Ditambahkan untuk membuka file manager
import 'package:excel/excel.dart'; // Ditambahkan untuk membaca file .xlsx
import '../services/excel_service.dart';
import 'package:share_plus/share_plus.dart';
import '../models/product_model.dart';
import '../services/local_db_service.dart'; // Diubah ke local_db_service

class ProductListController extends ChangeNotifier {
  final ExcelService _excelService = ExcelService();

  // --- Controllers & Form State ---
  late TextEditingController nameEditCtrl;
  late TextEditingController priceEditCtrl;
  late TextEditingController stockEditCtrl;
  String selectedEditCategory = 'Umum';

  // --- Product State ---
  List<Product> _allProducts = []; // Data mentah dari SQLite
  List<Product> products = []; // Data yang sudah difilter/sort untuk UI
  bool isLoading = true;
  bool isExporting = false;

  // --- Filter & Sort State ---
  String searchQuery = '';
  String selectedCategory = 'Semua';
  String _currentSort = 'name_asc';

  final List<String> editCategories = [
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
  List<String> get filterCategories => ['Semua', ...editCategories];
  String get currentSort => _currentSort;

  // --- Main Data Methods (CRUD) ---

  Future<void> fetchProducts() async {
    isLoading = true;
    notifyListeners();

    try {
      // Mengambil data produk langsung dari database lokal offline
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

      // Menyimpan hasil perubahan data ke database lokal offline
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
      // Melakukan proses soft delete langsung di database lokal offline
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

  /// **Fungsi Baru: Impor Produk dari File Excel (.xlsx)**
  Future<void> importProductsFromExcel(BuildContext context) async {
    try {
      // 1. Pilih berkas Excel dari penyimpanan HP
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null || result.files.single.path == null) return;

      isLoading = true;
      notifyListeners();

      // 2. Baca file menjadi bytes dan decode menggunakan package excel
      var bytes = File(result.files.single.path!).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      int jumlahSukses = 0;

      // 3. Iterasi setiap sheet yang ada di file Excel
      for (var table in excel.tables.keys) {
        var rows = excel.tables[table]!.rows;

        // Memulai dari indeks 1 karena indeks 0 adalah Header Kolom
        for (int i = 1; i < rows.length; i++) {
          var row = rows[i];
          if (row.isEmpty || row.length < 3) continue; // Validasi baris kosong

          /* Pemetaan kolom disesuaikan pas dengan file Excel Anda:
          row[0] = ID (Diabaikan karena SQLite otomatis Auto Increment)
          row[1] = Kode / Barcode Barang
          row[2] = Nama Barang
          row[3] = Kategori
          row[4] = Harga Jual
          row[5] = Sisa Stok
          */
          String code = row[1]?.value?.toString().trim() ?? '';
          String name = row[2]?.value?.toString().trim() ?? '';

          if (name.isEmpty)
            continue; // Nama produk wajib ada, jika kosong dilewati

          // Normalisasi nama kategori agar sesuai dengan daftar editCategories sistem Anda
          String categoryRaw = row[3]?.value?.toString().trim() ?? 'Umum';
          String category = editCategories.firstWhere(
            (cat) => cat.toLowerCase() == categoryRaw.toLowerCase(),
            orElse: () => 'Umum',
          );

          // Parsing angka secara aman dan membersihkan format titik/koma/simbol jika ada
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

          // 4. Masukkan langsung ke LocalDbService offline menggunakan named parameter code
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

      // 5. Refresh kembali data list di UI setelah selesai mengimpor
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
    nameEditCtrl = TextEditingController(text: product.name);
    priceEditCtrl = TextEditingController(text: product.price.toString());
    stockEditCtrl = TextEditingController(text: product.stock.toString());

    final incomingCategory = (product.category ?? 'Umum').trim().toLowerCase();
    selectedEditCategory = editCategories.firstWhere(
      (category) => category.toLowerCase() == incomingCategory,
      orElse: () => 'Umum',
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
          product.category.toLowerCase().contains(
            selectedCategory.toLowerCase(),
          );

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

  // --- Cleanup ---

  void disposeEditControllers() {
    nameEditCtrl.dispose();
    priceEditCtrl.dispose();
    stockEditCtrl.dispose();
  }
}
