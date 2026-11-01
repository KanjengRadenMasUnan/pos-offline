import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'add_product_page.dart';
import '../../config/app_theme.dart';
import '../../controllers/product_list_controller.dart';
import '../../models/product_model.dart';
import '../../utils/currency_format.dart';
import '../../widgets/shimmer_loading.dart';

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
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: const _ProductListAppBar(),
        body: const _Body(),
        floatingActionButton: const _AddButton(),
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
      title: const Text(
        "Katalog Produk",
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 17,
          color: AppTheme.textPrimary,
          letterSpacing: -0.2,
        ),
      ),
      actions: [
        Consumer<ProductListController>(
          builder: (context, controller, _) {
            return PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.cardBorderColor),
                ),
                child: const Icon(
                  Icons.import_export_rounded,
                  size: 18,
                  color: AppTheme.textPrimary,
                ),
              ),
              tooltip: "Kelola Excel",
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'export') {
                  controller.exportStokKeExcel();
                } else if (value == 'import') {
                  controller.importProductsFromExcel(context);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.upload_file_rounded, color: AppTheme.primaryColor, size: 18),
                      SizedBox(width: 10),
                      Text('Export ke Excel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'import',
                  child: Row(
                    children: [
                      Icon(Icons.download_for_offline_rounded, color: AppTheme.successColor, size: 18),
                      SizedBox(width: 10),
                      Text('Import dari Excel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const _SortButton(),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
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
        children: const [
          _SearchBar(),
          _CategoryFilter(),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}

// --- PRODUCT LIST & ANIMATION ---
class _ProductList extends StatelessWidget {
  const _ProductList();

  @override
  Widget build(BuildContext context) {
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

        return AnimationLimiter(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            itemCount: controller.products.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final product = controller.products[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 250),
                child: SlideAnimation(
                  verticalOffset: 20,
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

// --- SEARCH & FILTERS ---
class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Consumer<ProductListController>(
        builder: (_, controller, _) => Container(
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.cardBorderColor),
          ),
          child: TextField(
            onChanged: controller.setSearch,
            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: "Cari nama barang...",
              hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              prefixIcon: Icon(Icons.search, size: 20, color: AppTheme.textSecondary),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Consumer<ProductListController>(
        builder: (_, controller, _) => ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: controller.filterCategories.length,
          itemBuilder: (_, index) {
            final category = controller.filterCategories[index];
            final selected = controller.selectedCategory == category;

            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  HapticFeedback.lightImpact();
                  controller.setCategory(category);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primaryDark : AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? AppTheme.primaryDark : AppTheme.cardBorderColor,
                    ),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: selected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
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

// --- ACTIONS & COMPONENTS ---
class _SortButton extends StatelessWidget {
  const _SortButton();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductListController>(
      builder: (_, controller, _) => PopupMenuButton<String>(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.cardBorderColor),
          ),
          child: const Icon(Icons.sort_rounded, size: 18, color: AppTheme.textPrimary),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: controller.sortProducts,
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'name_asc', child: Text('Nama (A-Z)', style: TextStyle(fontSize: 13))),
          PopupMenuItem(value: 'name_desc', child: Text('Nama (Z-A)', style: TextStyle(fontSize: 13))),
          PopupMenuItem(value: 'price_asc', child: Text('Harga Termurah', style: TextStyle(fontSize: 13))),
          PopupMenuItem(value: 'price_desc', child: Text('Harga Termahal', style: TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: AppTheme.primaryDark,
      foregroundColor: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      icon: const Icon(Icons.add_rounded, size: 20),
      label: const Text(
        "Tambah Barang",
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              product.name.isNotEmpty ? product.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
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
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      CurrencyFormat.convertToIdr(product.price, 0),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isStockOut
                            ? AppTheme.errorColor.withValues(alpha: 0.1)
                            : (isStockLow
                                ? AppTheme.warningColor.withValues(alpha: 0.1)
                                : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isStockOut
                            ? "Habis"
                            : (isStockLow ? "Sisa ${product.stock}" : "Stok: ${product.stock}"),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isStockOut
                              ? AppTheme.errorColor
                              : (isStockLow ? AppTheme.warningColor : AppTheme.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textSecondary),
                tooltip: "Edit",
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onEdit();
                },
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.errorColor),
                tooltip: "Hapus",
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onDelete();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- DIALOGS & FORMS ---
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.textMuted),
          SizedBox(height: 12),
          Text(
            "Barang tidak ditemukan",
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _DeleteDialog {
  static void show(
    BuildContext context,
    Product product,
    ProductListController controller,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Hapus Produk?",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: Text(
          "Yakin ingin menghapus '${product.name}' dari katalog barang?",
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () async {
              final success = await controller.deleteProduct(product.id);
              if (context.mounted) Navigator.pop(context);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${product.name} berhasil dihapus")),
                );
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Edit Produk",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: _EditForm(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final success = await controller.saveEdit(product.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Data produk berhasil diperbarui")),
                );
              }
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
            decoration: const InputDecoration(labelText: "Nama Barang", isDense: true),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller.priceEditCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Harga Jual (Rp)", isDense: true),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller.stockEditCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Jumlah Stok", isDense: true),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: controller.selectedEditCategory,
            decoration: const InputDecoration(labelText: "Kategori", isDense: true),
            items: controller.filterCategories
                .where((c) => c != 'Semua')
                .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
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
