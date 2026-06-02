import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/product_model.dart';
import '../services/local_db_service.dart'; // Diubah ke local_db_service
import '../services/pdf_service.dart';

class BulkPrintController extends ChangeNotifier {
  final PdfService _pdfService = PdfService();

  // --- Data State ---
  List<Product> _allProducts = [];
  List<Product> filteredProducts = [];
  bool isLoading = true;

  /// Menyimpan jumlah cetak dengan format: {productId: quantity}
  Map<int, int> printQuantities = {};

  // --- Core Methods ---

  Future<void> loadProducts() async {
    isLoading = true;
    notifyListeners();

    try {
      // Mengambil daftar produk langsung dari database lokal offline
      _allProducts = await LocalDbService.instance.getAllProducts();
      filteredProducts = _allProducts;
    } catch (e) {
      // Anda bisa menambahkan penanganan error di sini jika perlu
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    if (query.isEmpty) {
      filteredProducts = _allProducts;
    } else {
      filteredProducts = _allProducts
          .where(
            (product) =>
                product.name.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
    notifyListeners();
  }

  // --- Quantity Management ---

  void incrementQty(int productId) {
    HapticFeedback.lightImpact();
    final current = printQuantities[productId] ?? 0;
    printQuantities[productId] = current + 1;
    notifyListeners();
  }

  void decrementQty(int productId) {
    final current = printQuantities[productId] ?? 0;

    if (current > 0) {
      HapticFeedback.lightImpact();
      printQuantities[productId] = current - 1;
      notifyListeners();
    }
  }

  int getTotalStickers() {
    int total = 0;
    printQuantities.forEach((_, value) {
      total += value;
    });
    return total;
  }

  // --- Printing Logic ---

  Future<void> printSelected(BuildContext context) async {
    final total = getTotalStickers();
    if (total == 0) return;

    isLoading = true;
    notifyListeners();

    try {
      final itemsToPrint = _prepareItemsForPrinting();

      if (itemsToPrint.isEmpty) {
        throw Exception('List kosong.');
      }

      await _pdfService.printBulkLabels(itemsToPrint);
    } catch (error) {
      _showPrintError(context, error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- Private Helpers ---

  List<Product> _prepareItemsForPrinting() {
    final List<Product> itemsToPrint = [];

    printQuantities.forEach((productId, quantity) {
      if (quantity <= 0) return;

      try {
        final product = _allProducts.firstWhere(
          (element) => element.id == productId,
        );

        for (int i = 0; i < quantity; i++) {
          itemsToPrint.add(product);
        }
      } catch (_) {
        // Melewati produk jika tidak ditemukan di list utama
      }
    });

    return itemsToPrint;
  }

  void _showPrintError(BuildContext context, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal: $error'), backgroundColor: Colors.red),
    );
  }
}
