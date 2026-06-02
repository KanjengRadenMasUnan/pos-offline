import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../controllers/bulk_print_controller.dart';
import '../../config/app_theme.dart';

class BulkPrintPage extends StatelessWidget {
  const BulkPrintPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BulkPrintController()..loadProducts(),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: _buildAppBar(),
        body: Column(children: [_SearchBar(), _ProductList(), _BottomBar()]),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text("Cetak Label Massal"),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 1,
    );
  }
}

// --- SEARCH SECTION ---

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Consumer<BulkPrintController>(
        builder: (_, controller, _) {
          return TextField(
            decoration: const InputDecoration(
              hintText: "Cari barang...",
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: controller.search,
          );
        },
      ),
    );
  }
}

// --- PRODUCT LIST SECTION ---

class _ProductList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Consumer<BulkPrintController>(
        builder: (_, controller, _) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.filteredProducts.isEmpty) {
            return _EmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: controller.filteredProducts.length,
            itemBuilder: (_, index) {
              return _ProductItem(product: controller.filteredProducts[index]);
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory, size: 50, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text("Tidak ada produk", style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}

// --- ITEM COMPONENTS ---

class _ProductItem extends StatelessWidget {
  final Product product;
  const _ProductItem({required this.product});

  @override
  Widget build(BuildContext context) {
    return Consumer<BulkPrintController>(
      builder: (_, controller, _) {
        final qty = controller.printQuantities[product.id] ?? 0;
        final selected = qty > 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: selected ? Border.all(color: Colors.green, width: 2) : null,
          ),
          child: Row(
            children: [
              Icon(
                Icons.qr_code,
                size: 40,
                color: selected ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 15),
              _ProductInfo(product: product),
              _QuantityControl(
                qty: qty,
                onAdd: () => controller.incrementQty(product.id),
                onRemove: () => controller.decrementQty(product.id),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductInfo extends StatelessWidget {
  final Product product;
  const _ProductInfo({required this.product});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            "Stok: ${product.stock}",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _QuantityControl({
    required this.qty,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(icon: const Icon(Icons.remove), onPressed: onRemove),
        Container(
          constraints: const BoxConstraints(minWidth: 30),
          alignment: Alignment.center,
          child: Text(
            "$qty",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(icon: const Icon(Icons.add), onPressed: onAdd),
      ],
    );
  }
}

// --- BOTTOM ACTION BAR ---

class _BottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BulkPrintController>(
      builder: (_, controller, _) {
        final total = controller.getTotalStickers();

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Total Label",
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      "$total Lembar",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text("CETAK PDF"),
                onPressed: total > 0
                    ? () => controller.printSelected(context)
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }
}
