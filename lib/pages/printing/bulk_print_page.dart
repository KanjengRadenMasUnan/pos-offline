import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/product_model.dart';
import '../../controllers/bulk_print_controller.dart';
import '../../controllers/tablet_mode_controller.dart';
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
      title: Row(
        children: [
          Text(
            "Cetak Label QR Barcode",
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: AppTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.surfaceRecessed,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.cardBorderColor),
            ),
            child: Text(
              "PDF UTILITY",
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- SEARCH SECTION ---
class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(color: AppTheme.cardBorderColor, width: 1),
        ),
      ),
      child: Consumer<BulkPrintController>(
        builder: (_, controller, _) {
          return Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceRecessed,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.cardBorderColor),
            ),
            child: TextField(
              style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: "Cari produk dengan nama atau kode...",
                hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textSecondary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
    final isTablet = context.watch<TabletModeController>().isTabletLayout(context);

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
          return const _EmptyState();
        }

        if (isTablet) {
          return GridView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.8,
            ),
            itemCount: controller.filteredProducts.length,
            itemBuilder: (_, index) {
              return _ProductItem(product: controller.filteredProducts[index]);
            },
          );
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
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 36, color: AppTheme.textMuted),
          const SizedBox(height: 10),
          Text(
            "Tidak ada produk ditemukan",
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600),
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
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppTheme.primaryColor : AppTheme.cardBorderColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primaryColor
                      : AppTheme.surfaceRecessed,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.qr_code_2_rounded,
                  size: 20,
                  color: selected ? Colors.white : AppTheme.textSecondary,
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
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "Stok gudang: ${product.stock} pcs",
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10.5,
              color: AppTheme.textMuted,
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
        color: AppTheme.surfaceRecessed,
        borderRadius: BorderRadius.circular(6),
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
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12.5,
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceColor,
            border: Border(
              top: BorderSide(color: AppTheme.cardBorderColor, width: 1),
            ),
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
                      Text(
                        "TOTAL CETAK",
                        style: GoogleFonts.jetBrainsMono(
                          color: AppTheme.textSecondary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        "$total Lembar Label",
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: total > 0 ? AppTheme.primaryColor : const Color(0xFFCBD5E1),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  icon: const Icon(Icons.print_rounded, size: 16),
                  label: Text(
                    "BUAT DOKUMEN PDF",
                    style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5),
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
