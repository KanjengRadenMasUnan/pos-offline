import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        body: Column(
          children: [
            _SearchBar(),
            const Expanded(child: _ProductList()),
            _BottomBar(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        "Cetak Label QR Barcode",
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 17,
          color: AppTheme.textPrimary,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

// --- SEARCH SECTION ---
class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.cardBorderColor, width: 1),
        ),
      ),
      child: Consumer<BulkPrintController>(
        builder: (_, controller, _) {
          return Container(
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.cardBorderColor),
            ),
            child: TextField(
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: "Cari produk untuk dicetak...",
                hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                prefixIcon: Icon(Icons.search, size: 20, color: AppTheme.textSecondary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              ),
              onChanged: controller.search,
            ),
          );
        },
      ),
    );
  }
}

// --- PRODUCT LIST SECTION ---
class _ProductList extends StatelessWidget {
  const _ProductList();

  @override
  Widget build(BuildContext context) {
    return Consumer<BulkPrintController>(
      builder: (_, controller, _) {
        if (controller.isLoading) {
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.primaryColor,
              ),
            ),
          );
        }

        if (controller.filteredProducts.isEmpty) {
          return _EmptyState();
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          itemCount: controller.filteredProducts.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            return _ProductItem(product: controller.filteredProducts[index]);
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.textMuted),
          SizedBox(height: 12),
          Text(
            "Tidak ada produk ditemukan",
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
          ),
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.primaryColor : AppTheme.cardBorderColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.qr_code_2_rounded,
                  size: 22,
                  color: selected ? AppTheme.primaryColor : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              _ProductInfo(product: product),
              const SizedBox(width: 8),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "Stok saat ini: ${product.stock}",
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
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
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cardBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: qty > 0 ? onRemove : null,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.remove,
                size: 14,
                color: qty > 0 ? AppTheme.textPrimary : AppTheme.textMuted,
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 26),
            alignment: Alignment.center,
            child: Text(
              "$qty",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: qty > 0 ? AppTheme.primaryColor : AppTheme.textSecondary,
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onAdd,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.add, size: 14, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
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
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
              top: BorderSide(color: AppTheme.cardBorderColor, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "TOTAL STIKER",
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        "$total Lembar",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: total > 0 ? AppTheme.primaryDark : const Color(0xFFCBD5E1),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.print_rounded, size: 18),
                  label: const Text(
                    "CETAK PDF",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
                  ),
                  onPressed: total > 0
                      ? () {
                          HapticFeedback.mediumImpact();
                          controller.printSelected(context);
                        }
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
