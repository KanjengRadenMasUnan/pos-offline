import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        backgroundColor: AppTheme.backgroundColor,
        appBar: const _AppBar(),
        body: const _Body(),
      ),
    );
  }
}

/* ================= APP BAR ================= */
class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        "Input Barang Baru",
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 17,
          color: AppTheme.textPrimary,
          letterSpacing: -0.2,
        ),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.cardBorderColor),
            ),
            child: const Icon(
              Icons.search_rounded,
              size: 18,
              color: AppTheme.textPrimary,
            ),
          ),
          tooltip: "Cari data lama",
          onPressed: () => _showSearchSheet(context),
        ),
        const SizedBox(width: 8),
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
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ScannerSection(controller: controller),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.cardBorderColor, width: 1),
                ),
                child: _FormSection(controller: controller),
              ),
              const SizedBox(height: 24),
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _openScanner(context, controller);
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasCode ? AppTheme.successColor : AppTheme.cardBorderColor,
              width: hasCode ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: hasCode
                      ? AppTheme.successColor.withValues(alpha: 0.1)
                      : AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  hasCode ? Icons.qr_code_2_rounded : Icons.qr_code_scanner_rounded,
                  color: hasCode ? AppTheme.successColor : AppTheme.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: hasCode
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Barcode Terdeteksi",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.successColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            controller.scannedBarcode!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Scan Barcode Barang",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Ketuk untuk scan kamera (opsional)",
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
              ),
              if (hasCode)
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    controller.resetScan();
                  },
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: AppTheme.errorColor,
                )
              else
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppTheme.textMuted,
                ),
            ],
          ),
        ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InputField(
          label: "Nama Barang",
          hint: "Contoh: Kuota Telkomsel 10GB",
          controller: controller.nameController,
        ),
        const SizedBox(height: 16),
        _InputField(
          label: "Harga Jual (Rp)",
          hint: "Contoh: 35000",
          controller: controller.priceController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _InputField(
          label: "Stok Awal",
          hint: "Contoh: 20",
          controller: controller.stockController,
          keyboardType: TextInputType.number,
          onSubmit: (_) => _handleSave(context, controller),
        ),
        const SizedBox(height: 16),
        _CategoryField(controller: controller),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final Function(String)? onSubmit;

  const _InputField({
    required this.label,
    this.hint,
    required this.controller,
    this.keyboardType,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.cardBorderColor),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            onSubmitted: onSubmit,
            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Kategori Produk",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppTheme.textPrimary,
              ),
            ),
            InkWell(
              onTap: () => _showAddCategoryDialog(context, controller),
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  "+ Tambah Baru",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.cardBorderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: controller.selectedCategory,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              items: controller.categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => controller.setCategory(val),
            ),
          ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Tambah Kategori',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
      content: TextField(
        controller: textCtrl,
        autofocus: true,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Nama kategori baru...',
          hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          filled: true,
          fillColor: AppTheme.backgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.cardBorderColor),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onPressed: () async {
            final name = textCtrl.text.trim();
            if (name.isEmpty) return;
            final success = await controller.addCategory(name);
            if (ctx.mounted) Navigator.pop(ctx);
            if (success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Kategori "$name" berhasil ditambahkan')),
              );
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kategori sudah ada atau tidak valid'),
                ),
              );
            }
          },
          child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: controller.isLoading
            ? null
            : () => _handleSave(context, controller),
        child: controller.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text(
                "SIMPAN PRODUK",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
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
    ).showSnackBar(const SnackBar(content: Text("Data produk berhasil disimpan")));
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppTheme.successColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Produk Tersimpan",
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              "QR Barcode otomatis berhasil dibuat:",
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.cardBorderColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SizedBox(
                height: 150,
                width: 150,
                child: QrImageView(
                  data: SecurityService.encryptData(product.code),
                  size: 150,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              product.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              product.code,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontFamily: 'monospace',
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppTheme.cardBorderColor),
                    ),
                    child: const Text("Tutup", style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => pdfService.printWithDialog(context, product),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.print_rounded, size: 16),
                    label: const Text("Cetak PDF", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
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
    backgroundColor: Colors.transparent,
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Cari Data Barang Lama",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.cardBorderColor),
            ),
            child: TextField(
              autofocus: true,
              onChanged: _search,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: "Ketik nama barang...",
                hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                prefixIcon: Icon(Icons.search, size: 20, color: AppTheme.textSecondary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : (results.isEmpty
                    ? const Center(
                        child: Text("Ketik minimal 2 huruf untuk mencari", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      )
                    : ListView.separated(
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemCount: results.length,
                        itemBuilder: (_, i) {
                          final p = results[i];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                            title: Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: Text("Stok: ${p.stock} • Rp ${p.price}", style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                            trailing: const Icon(Icons.chevron_right, size: 16, color: AppTheme.textMuted),
                            onTap: () => widget.onSelect(p),
                          );
                        },
                      )),
          ),
        ],
      ),
    );
  }
}
