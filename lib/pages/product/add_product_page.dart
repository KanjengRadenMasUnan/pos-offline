import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/scanner_view.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../controllers/add_product_controller.dart';
import '../../models/product_model.dart';
import '../../services/pdf_service.dart';
import '../../services/security_service.dart';
import '../../config/app_theme.dart';

class AddProductPage extends StatelessWidget {
  const AddProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddProductController(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _AppBar(),
        body: const _Body(),
      ),
    );
  }
}

/* ================= APP BAR ================= */
class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text("Input Barang Baru"),
      elevation: 1,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: "Cari data lama",
          onPressed: () => _showSearchSheet(context),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/* ================= BODY ================= */
class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return Consumer<AddProductController>(
      builder: (_, controller, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ScannerSection(controller: controller),
              const SizedBox(height: 25),
              _FormSection(controller: controller),
              const SizedBox(height: 40),
              _SaveButton(controller: controller),
            ],
          ),
        );
      },
    );
  }
}

/* ================= SCANNER ================= */
class _ScannerSection extends StatelessWidget {
  final AddProductController controller;
  const _ScannerSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    final hasCode = controller.scannedBarcode != null;
    return InkWell(
      onTap: () => _openScanner(context, controller),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _decoration(hasCode),
        child: Row(
          children: [
            _ScannerIcon(hasCode: hasCode),
            const SizedBox(width: 15),
            _ScannerInfo(controller: controller),
            if (hasCode)
              IconButton(
                onPressed: controller.resetScan,
                icon: const Icon(Icons.close, size: 18),
                color: Colors.red,
              ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _decoration(bool hasCode) {
    return BoxDecoration(
      color: hasCode ? Colors.green.shade50 : Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: hasCode ? Colors.green : Colors.grey.shade300,
        width: 1.5,
      ),
    );
  }
}

class _ScannerIcon extends StatelessWidget {
  final bool hasCode;
  const _ScannerIcon({required this.hasCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: hasCode ? Colors.white : Colors.grey.shade200,
        shape: BoxShape.circle,
      ),
      child: Icon(
        hasCode ? Icons.qr_code_2 : Icons.qr_code_scanner,
        color: hasCode ? Colors.green : Colors.grey,
      ),
    );
  }
}

class _ScannerInfo extends StatelessWidget {
  final AddProductController controller;
  const _ScannerInfo({required this.controller});

  @override
  Widget build(BuildContext context) {
    final code = controller.scannedBarcode;
    return Expanded(
      child: code != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Barcode Terdeteksi",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  code,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Scan Barcode",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "Tap untuk scan kamera",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
    );
  }
}

/* ================= FORM ================= */
class _FormSection extends StatelessWidget {
  final AddProductController controller;
  const _FormSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InputField(
          label: "Nama Barang",
          controller: controller.nameController,
        ),
        const SizedBox(height: 20),
        _InputField(
          label: "Harga Jual (Rp)",
          controller: controller.priceController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        _InputField(
          label: "Stok Awal",
          controller: controller.stockController,
          keyboardType: TextInputType.number,
          onSubmit: (_) => controller.saveProduct(context),
        ),
        const SizedBox(height: 20),
        _CategoryField(controller: controller),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final Function(String)? onSubmit;

  const _InputField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onSubmitted: onSubmit,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ],
    );
  }
}

class _CategoryField extends StatelessWidget {
  final AddProductController controller;
  const _CategoryField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Kategori Produk",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: controller.selectedCategory,
                items: controller.categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => controller.setCategory(val),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
              onPressed: () => _showAddCategoryDialog(context, controller),
              tooltip: 'Tambah Kategori Baru',
            ),
          ],
        ),
      ],
    );
  }
}

void _showAddCategoryDialog(
  BuildContext context,
  AddProductController controller,
) {
  final textCtrl = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Tambah Kategori'),
      content: TextField(
        controller: textCtrl,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Nama kategori',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () async {
            final name = textCtrl.text.trim();
            if (name.isEmpty) return;
            final success = await controller.addCategory(name);
            if (ctx.mounted) Navigator.pop(ctx);
            if (success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Kategori "$name" ditambahkan')),
              );
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kategori sudah ada atau tidak valid'),
                ),
              );
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}

/* ================= SAVE ================= */
class _SaveButton extends StatelessWidget {
  final AddProductController controller;
  const _SaveButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        onPressed: controller.isLoading
            ? null
            : () => _handleSave(context, controller),
        child: controller.isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "SIMPAN BARANG",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
      ),
    );
  }
}

/* ================= HELPERS ================= */
Future<void> _handleSave(
  BuildContext context,
  AddProductController controller,
) async {
  final product = await controller.saveProduct(context);
  if (product == null || !context.mounted) return;

  if (controller.scannedBarcode == null) {
    _showQrDialog(context, product);
  } else {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Data berhasil disimpan")));
  }
}

void _openScanner(BuildContext context, AddProductController controller) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          ScannerView(onDetect: (code) => controller.setScannedCode(code)),
    ),
  );
}

void _showQrDialog(BuildContext context, Product product) {
  final pdfService = PdfService();

  showDialog(
    context: context,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.green,
                size: 40,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "Produk Tersimpan",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 5),
            Text(
              "Barcode otomatis dibuat untuk:",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SizedBox(
                height: 160,
                width: 160,
                child: QrImageView(
                  data: SecurityService.encryptData(product.code),
                  size: 160,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              product.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              product.code,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontFamily: 'monospace',
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Tutup"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        pdfService.printWithDialog(context, product),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text("Cetak"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/* ================= SEARCH SHEET ================= */
void _showSearchSheet(BuildContext context) {
  final controller = context.read<AddProductController>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _SearchSheet(
      onSearch: controller.searchProducts,
      onSelect: (product) {
        controller.fillFormFromExisting(product);
        Navigator.pop(context);
      },
    ),
  );
}

class _SearchSheet extends StatefulWidget {
  final Future<List<Product>> Function(String) onSearch;
  final Function(Product) onSelect;

  const _SearchSheet({required this.onSearch, required this.onSelect});

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  bool loading = false;
  List<Product> results = [];

  Future<void> _search(String query) async {
    if (query.length < 2) return;
    setState(() => loading = true);
    results = await widget.onSearch(query);
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            "Cari Produk",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 15),
          TextField(
            autofocus: true,
            onChanged: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    separatorBuilder: (_, _) => const Divider(),
                    itemCount: results.length,
                    itemBuilder: (_, i) {
                      final p = results[i];
                      return ListTile(
                        title: Text(p.name),
                        onTap: () => widget.onSelect(p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
