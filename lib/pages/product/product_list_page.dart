import 'package:flutter/material.dart';
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
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: const _ProductListAppBar(),
        body: const _Body(),
        floatingActionButton: const _AddButton(),
      ),
    );
  }
}

// --- APP BAR ---
class _ProductListAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _ProductListAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      title: const Text(
        "Stok Barang",
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
      ),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      actions: [
        Consumer<ProductListController>(
          builder: (context, controller, _) {
            return PopupMenuButton<String>(
              icon: const Icon(
                Icons.import_export_rounded,
                color: Colors.indigo,
              ),
              tooltip: "Kelola Excel",
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
                      Icon(Icons.upload_rounded, color: Colors.indigo),
                      SizedBox(width: 10),
                      Text('Export Excel'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'import',
                  child: Row(
                    children: [
                      Icon(Icons.download_rounded, color: Colors.green),
                      SizedBox(width: 10),
                      Text('Import Excel'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const _SortButton(),
        const SizedBox(width: 10),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: const [_SearchBar(), _CategoryFilter(), SizedBox(height: 10)],
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
            padding: EdgeInsets.all(15),
            child: ShimmerList(),
          );
        }

        if (controller.products.isEmpty) {
          return const _EmptyState();
        }

        return AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: controller.products.length,
            itemBuilder: (_, index) {
              final product = controller.products[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 350),
                child: SlideAnimation(
                  verticalOffset: 50,
                  child: FadeInAnimation(
                    child: _ProductCard(
                      product: product,
                      onEdit: () =>
                          _EditDialog.show(context, product, controller),
                      onDelete: () =>
                          _DeleteDialog.show(context, product, controller),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Consumer<ProductListController>(
        builder: (_, controller, _) => TextField(
          onChanged: controller.setSearch,
          decoration: InputDecoration(
            hintText: "Cari nama barang...",
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
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
      height: 40,
      child: Consumer<ProductListController>(
        builder: (_, controller, _) => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          itemCount: controller.filterCategories.length,
          itemBuilder: (_, index) {
            final category = controller.filterCategories[index];
            final selected = controller.selectedCategory == category;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(category),
                selected: selected,
                onSelected: (_) => controller.setCategory(category),
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: selected ? AppTheme.primaryColor : Colors.black87,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                checkmarkColor: AppTheme.primaryColor,
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
        icon: const Icon(Icons.sort_rounded),
        onSelected: controller.sortProducts,
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'name_asc', child: Text('Nama (A-Z)')),
          PopupMenuItem(value: 'name_desc', child: Text('Nama (Z-A)')),
          PopupMenuItem(value: 'price_asc', child: Text('Termurah')),
          PopupMenuItem(value: 'price_desc', child: Text('Termahal')),
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
      backgroundColor: AppTheme.primaryColor,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text("Barang Baru", style: TextStyle(color: Colors.white)),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddProductPage()),
        ).then((_) {
          context.read<ProductListController>().fetchProducts();
        });
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
    final bool isStockLow = product.stock <= 5;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                product.name.isNotEmpty ? product.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyFormat.convertToIdr(product.price, 0),
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 14,
                        color: isStockLow ? Colors.red : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Stok: ${product.stock}",
                        style: TextStyle(
                          fontSize: 13,
                          color: isStockLow ? Colors.red : Colors.grey[600],
                          fontWeight: isStockLow
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _CardActions(onEdit: onEdit, onDelete: onDelete),
          ],
        ),
      ),
    );
  }
}

class _CardActions extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _CardActions({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionButton(icon: Icons.edit, color: Colors.blue, onTap: onEdit),
        const SizedBox(height: 8),
        _ActionButton(icon: Icons.delete, color: Colors.red, onTap: onDelete),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
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
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            "Barang tidak ditemukan",
            style: TextStyle(color: Colors.grey[500]),
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
        title: const Text("Hapus Barang?"),
        content: Text("Yakin hapus '${product.name}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final success = await controller.deleteProduct(product.id);
              if (context.mounted) Navigator.pop(context);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${product.name} terhapus")),
                );
              }
            },
            child: const Text("HAPUS", style: TextStyle(color: Colors.white)),
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
        title: const Text("Edit Barang"),
        content: _EditForm(controller: controller),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await controller.saveEdit(product.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Berhasil diupdate")),
                );
              }
            },
            child: const Text("Simpan"),
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
            decoration: const InputDecoration(labelText: "Nama"),
          ),
          TextField(
            controller: controller.priceEditCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Harga"),
          ),
          TextField(
            controller: controller.stockEditCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Stok"),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: controller.selectedEditCategory,
            decoration: const InputDecoration(labelText: "Kategori"),
            items: controller.filterCategories
                .where((c) => c != 'Semua') // hanya kategori asli
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
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
