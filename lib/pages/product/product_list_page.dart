import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'add_product_page.dart';
import '../../controllers/product_list_controller.dart';
import '../../controllers/tablet_mode_controller.dart';
import '../../models/product_model.dart';
import '../../utils/currency_format.dart';
import '../../widgets/shimmer_loading.dart';
import '../../config/app_theme.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late final ProductListController controller;

  @override
  void initState() {
    super.initState();
    controller = ProductListController()..fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: _ProductListAppBar(),
        body: _Body(),
        floatingActionButton: _AddButton(),
      ),
    );
  }
}

// --- APP BAR ---
class _ProductListAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ProductListAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppTheme.cardBorderColor, height: 1),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Text(
            "Katalog Produk",
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
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
              "INVENTORY",
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Consumer<ProductListController>(
          builder: (context, controller, _) {
            return PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceRecessed,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.cardBorderColor),
                ),
                child: const Icon(
                  Icons.import_export_rounded,
                  size: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
              tooltip: "Kelola Excel",
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppTheme.cardBorderColor),
              ),
              onSelected: (value) {
                if (value == 'export') {
                  controller.exportStokKeExcel();
                } else if (value == 'import') {
                  controller.importProductsFromExcel(context);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      const Icon(Icons.upload_file_rounded, color: AppTheme.textPrimary, size: 16),
                      const SizedBox(width: 10),
                      Text(
                        'Export ke Excel',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'import',
                  child: Row(
                    children: [
                      const Icon(Icons.download_for_offline_rounded, color: AppTheme.forestGreen, size: 16),
                      const SizedBox(width: 10),
                      Text(
                        'Import dari Excel',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(width: 6),
        const _SortButton(),
        const SizedBox(width: 12),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);
}

// --- MAIN BODY STRUCTURE ---
class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _HeaderSection(),
        Expanded(child: _ProductList()),
      ],
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.cardBorderColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _CatalogMetricsStrip(),
          _SearchBar(),
          _CategoryFilter(),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}

// --- SUMMARY METRICS STRIP ---
class _CatalogMetricsStrip extends StatelessWidget {
  const _CatalogMetricsStrip();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductListController>(
      builder: (_, controller, _) {
        final totalSKU = controller.totalProductsCount;
        final totalVal = controller.totalStockValuation;
        final lowStock = controller.lowStockCount;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              _buildMetricChip(
                code: "TOTAL-SKU",
                label: "Total Item",
                value: "$totalSKU SKU",
                accentColor: AppTheme.textPrimary,
              ),
              const SizedBox(width: 8),
              _buildMetricChip(
                code: "VALUATION",
                label: "Nilai Aset Stok",
                value: CurrencyFormat.convertToIdr(totalVal, 0),
                accentColor: AppTheme.textPrimary,
              ),
              const SizedBox(width: 8),
              _buildMetricChip(
                code: "STOCK-ALERT",
                label: "Item Menipis",
                value: lowStock > 0 ? "$lowStock Barang" : "Semua Aman",
                accentColor: lowStock > 0 ? AppTheme.rawBrass : AppTheme.forestGreen,
                isAlert: lowStock > 0,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricChip({
    required String code,
    required String label,
    required String value,
    required Color accentColor,
    bool isAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRecessed,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isAlert ? AppTheme.rawBrass.withValues(alpha: 0.5) : AppTheme.cardBorderColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: AppTheme.cardBorderColor),
            ),
            child: Text(
              code,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.5,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- SEARCH BAR ---
class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Consumer<ProductListController>(
        builder: (_, controller, _) => Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.surfaceRecessed,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.cardBorderColor),
          ),
          child: TextField(
            onChanged: controller.setSearch,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: "Cari nama atau barcode produk...",
              hintStyle: GoogleFonts.plusJakartaSans(
                color: AppTheme.textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.textSecondary),
              suffixIcon: controller.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16, color: AppTheme.textSecondary),
                      onPressed: () => controller.setSearch(''),
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ),
    );
  }
}

// --- CATEGORY FILTER CHIPS ---
class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Consumer<ProductListController>(
        builder: (_, controller, _) => ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: controller.filterCategories.length,
          itemBuilder: (_, index) {
            final category = controller.filterCategories[index];
            final selected = controller.selectedCategory == category;
            final count = controller.countForCategory(category);

            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  HapticFeedback.lightImpact();
                  controller.setCategory(category);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primaryDark : AppTheme.surfaceRecessed,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: selected ? AppTheme.primaryDark : AppTheme.cardBorderColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        category,
                        style: GoogleFonts.plusJakartaSans(
                          color: selected ? Colors.white : AppTheme.textSecondary,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.18)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: selected ? Colors.transparent : AppTheme.cardBorderColor,
                          ),
                        ),
                        child: Text(
                          "$count",
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// --- SORT BUTTON ---
class _SortButton extends StatelessWidget {
  const _SortButton();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductListController>(
      builder: (_, controller, _) => PopupMenuButton<String>(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.surfaceRecessed,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.cardBorderColor),
          ),
          child: const Icon(Icons.sort_rounded, size: 16, color: AppTheme.textPrimary),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppTheme.cardBorderColor),
        ),
        onSelected: controller.sortProducts,
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'name_asc',
            child: Text('Nama (A-Z)', style: GoogleFonts.plusJakartaSans(fontSize: 12.5)),
          ),
          PopupMenuItem(
            value: 'name_desc',
            child: Text('Nama (Z-A)', style: GoogleFonts.plusJakartaSans(fontSize: 12.5)),
          ),
          PopupMenuItem(
            value: 'price_asc',
            child: Text('Harga Termurah', style: GoogleFonts.plusJakartaSans(fontSize: 12.5)),
          ),
          PopupMenuItem(
            value: 'price_desc',
            child: Text('Harga Termahal', style: GoogleFonts.plusJakartaSans(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}

// --- ADD FLOATING ACTION BUTTON ---
class _AddButton extends StatelessWidget {
  const _AddButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: Text(
        "Tambah Barang",
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
          letterSpacing: 0.2,
        ),
      ),
      onPressed: () async {
        HapticFeedback.lightImpact();
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddProductPage()),
        );
        if (context.mounted) {
          context.read<ProductListController>().fetchProducts();
        }
      },
    );
  }
}

// --- PRODUCT LIST & RESPONSIVE GRID ---
class _ProductList extends StatelessWidget {
  const _ProductList();

  @override
  Widget build(BuildContext context) {
    final isTablet = context.watch<TabletModeController>().isTabletLayout(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Consumer<ProductListController>(
      builder: (_, controller, _) {
        if (controller.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: ShimmerList(),
          );
        }

        if (controller.products.isEmpty) {
          return const _EmptyState();
        }

        // Horizontal tablet or wider displays
        if (isTablet || screenWidth >= 700) {
          final crossAxisCount = screenWidth > 1050 ? 3 : 2;
          return AnimationLimiter(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.1,
              ),
              itemCount: controller.products.length,
              itemBuilder: (_, index) {
                final product = controller.products[index];
                return _ProductCard(
                  product: product,
                  onEdit: () => _EditDialog.show(context, product, controller),
                  onDelete: () => _DeleteDialog.show(context, product, controller),
                );
              },
            ),
          );
        }

        // Standard mobile portrait layout
        return AnimationLimiter(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: controller.products.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, index) {
              final product = controller.products[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 200),
                child: SlideAnimation(
                  verticalOffset: 12,
                  child: FadeInAnimation(
                    child: _ProductCard(
                      product: product,
                      onEdit: () => _EditDialog.show(context, product, controller),
                      onDelete: () => _DeleteDialog.show(context, product, controller),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// --- ARCHITECTURAL PRODUCT CARD ---
class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isStockOut = product.stock <= 0;
    final bool isStockLow = !isStockOut && product.stock <= 5;

    final Color statusColor = isStockOut
        ? AppTheme.stampRed
        : (isStockLow ? AppTheme.rawBrass : AppTheme.forestGreen);

    final String statusText = isStockOut
        ? "HABIS"
        : (isStockLow ? "SISA ${product.stock}" : "STOK ${product.stock}");

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isStockOut
              ? AppTheme.stampRed.withValues(alpha: 0.5)
              : AppTheme.cardBorderColor,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            HapticFeedback.lightImpact();
            onEdit();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Tag Row: Code + Category + Stock Status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceRecessed,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.cardBorderColor),
                      ),
                      child: Text(
                        product.code.isNotEmpty ? product.code : "#${product.id}",
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.cardBorderColor),
                        ),
                        child: Text(
                          product.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Stock Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Product Name
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.2,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),

                // Divider hairline
                const Divider(height: 1, color: AppTheme.cardBorderColor),
                const SizedBox(height: 8),

                // Bottom Row: Price + Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "HARGA JUAL",
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          CurrencyFormat.convertToIdr(product.price, 0),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onEdit();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceRecessed,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.cardBorderColor),
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onDelete();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.stampRed.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.stampRed.withValues(alpha: 0.3)),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              size: 14,
                              color: AppTheme.stampRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- EMPTY STATE ---
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProductListController>();
    final isSearching = controller.searchQuery.isNotEmpty || controller.selectedCategory != 'Semua';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.surfaceRecessed,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.cardBorderColor),
              ),
              child: const Icon(Icons.inventory_2_outlined, size: 24, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            Text(
              isSearching ? "Barang Tidak Ditemukan" : "Katalog Produk Kosong",
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? "Coba periksa kata kunci pencarian atau ganti filter kategori barang."
                  : "Belum ada produk yang tersimpan. Tekan tombol di bawah untuk menambah barang.",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 12),
            ),
            if (!isSearching) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  elevation: 0,
                ),
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductPage()));
                  if (context.mounted) context.read<ProductListController>().fetchProducts();
                },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  "TAMBAH PRODUK PERTAMA",
                  style: GoogleFonts.jetBrainsMono(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- DIALOG HAPUS ---
class _DeleteDialog {
  static void show(
    BuildContext context,
    Product product,
    ProductListController controller,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppTheme.cardBorderColor),
        ),
        title: Text(
          "Hapus Produk?",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary),
        ),
        content: Text(
          "Yakin ingin menghapus '${product.name}' dari katalog barang toko?",
          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Batal",
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.stampRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              elevation: 0,
            ),
            onPressed: () async {
              final success = await controller.deleteProduct(product.id);
              if (context.mounted) Navigator.pop(context);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${product.name} berhasil dihapus", style: GoogleFonts.plusJakartaSans()),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                );
              }
            },
            child: Text(
              "HAPUS",
              style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

// --- DIALOG EDIT ---
class _EditDialog {
  static void show(
    BuildContext context,
    Product product,
    ProductListController controller,
  ) {
    controller.prepareEdit(product);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppTheme.cardBorderColor),
        ),
        title: Text(
          "Edit Data Produk",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary),
        ),
        content: _EditForm(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Batal",
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(context);
              final success = await controller.saveEdit(product.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Data produk berhasil diperbarui", style: GoogleFonts.plusJakartaSans()),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                );
              }
            },
            child: Text(
              "SIMPAN",
              style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditForm extends StatelessWidget {
  final ProductListController controller;
  const _EditForm({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller.nameEditCtrl,
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
            decoration: InputDecoration(
              labelText: "Nama Barang",
              labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.surfaceRecessed,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppTheme.cardBorderColor),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller.priceEditCtrl,
            keyboardType: TextInputType.number,
            style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              labelText: "Harga Jual (Rp)",
              labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.surfaceRecessed,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppTheme.cardBorderColor),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller.stockEditCtrl,
            keyboardType: TextInputType.number,
            style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              labelText: "Jumlah Stok",
              labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.surfaceRecessed,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppTheme.cardBorderColor),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: controller.selectedEditCategory,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: "Kategori",
              labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.surfaceRecessed,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppTheme.cardBorderColor),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: controller.filterCategories
                .where((c) => c != 'Semua')
                .map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.plusJakartaSans(fontSize: 13))))
                .toList(),
            onChanged: (v) {
              if (v != null) controller.selectedEditCategory = v;
            },
          ),
        ],
      ),
    );
  }
}
