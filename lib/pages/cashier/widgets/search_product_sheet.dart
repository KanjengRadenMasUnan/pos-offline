import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/cashier_controller.dart';
import '../../../models/product_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../utils/currency_format.dart';

class SearchProductSheet extends StatefulWidget {
  const SearchProductSheet({super.key});

  @override
  State<SearchProductSheet> createState() => _SearchProductSheetState();
}

class _SearchProductSheetState extends State<SearchProductSheet> {
  final TextEditingController _searchCtrl = TextEditingController();

  // --- Lifecycle ---

  @override
  void initState() {
    super.initState();
    _initializeSearch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _initializeSearch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CashierController>().clearSearch();
    });
  }

  // --- Main Build ---

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 10),
              _buildSearchField(),
              const SizedBox(height: 10),
              Expanded(child: _buildSearchResults(scrollController)),
            ],
          ),
        );
      },
    );
  }

  // --- Header & Input Widgets ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Cari Produk',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchCtrl,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Ketik nama barang...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
      ),
      onChanged: (value) {
        context.read<CashierController>().searchProducts(value);
      },
    );
  }

  // --- Search Results Logic ---

  Widget _buildSearchResults(ScrollController scrollController) {
    return Consumer2<CashierController, CartProvider>(
      builder: (context, cashierCtrl, cart, _) {
        final results = cashierCtrl.searchResults;

        if (_searchCtrl.text.isEmpty) {
          return _buildEmptySearchState();
        }

        if (results.isEmpty) {
          return _buildNoResultsState();
        }

        return ListView.separated(
          controller: scrollController,
          itemCount: results.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (context, index) {
            return _buildProductItem(
              context,
              results[index],
              cashierCtrl,
              cart,
            );
          },
        );
      },
    );
  }

  // --- Item & State Widgets ---

  Widget _buildProductItem(
    BuildContext context,
    Product product,
    CashierController controller,
    CartProvider cart,
  ) {
    final remainingStock = _calculateRemainingStock(product, cart);
    final hasStock = remainingStock > 0;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        product.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'Stok: $remainingStock  |  ${CurrencyFormat.convertToIdr(product.price, 0)}',
        style: TextStyle(color: hasStock ? Colors.grey[600] : Colors.red),
      ),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: hasStock ? Colors.green : Colors.grey,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(10),
        ),
        onPressed: hasStock
            ? () => controller.addToCartFromSearch(product, cart)
            : null,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.keyboard, size: 50, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            'Ketik nama barang untuk mencari',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Text(
        'Barang tidak ditemukan',
        style: TextStyle(color: Colors.grey[400]),
      ),
    );
  }

  // --- Helper Logic ---

  int _calculateRemainingStock(Product product, CartProvider cart) {
    try {
      final cartItem = cart.items.firstWhere(
        (item) => item.product.id == product.id,
      );
      return product.stock - cartItem.qty;
    } catch (_) {
      return product.stock;
    }
  }
}
