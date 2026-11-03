import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../widgets/scanner_view.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../controllers/add_product_controller.dart';
import '../../controllers/tablet_mode_controller.dart';
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
      child: const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: _AppBar(),
        body: _Body(),
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
            "Input Barang Baru",
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
              "SKU-ENTRY",
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
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceRecessed,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.cardBorderColor),
            ),
            child: const Icon(
              Icons.search_rounded,
              size: 16,
              color: AppTheme.textPrimary,
            ),
          ),
          tooltip: "Cari data lama",
          onPressed: () => _showSearchSheet(context),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);
}

/* ================= BODY ================= */
class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final isTablet = context.watch<TabletModeController>().isTabletLayout(context);

    return Consumer<AddProductController>(
      builder: (_, controller, _) {
        if (isTablet) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ScannerSection(controller: controller),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.cardBorderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceRecessed,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppTheme.cardBorderColor),
                                  ),
                                  child: const Icon(
                                    Icons.qr_code_2_rounded,
                                    size: 18,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Label & Barcode Produk",
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        "Format kompatibel POS & thermal",
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 10,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: AppTheme.cardBorderColor),
                            const SizedBox(height: 12),
                            Text(
                              "• Jika produk memiliki barcode fisik pada kemasan, scan kamera atau gunakan barcode reader scanner USB/Bluetooth.\n• Jika produk tidak memiliki barcode, sistem akan membuatkan kode QR terenkripsi secara otomatis saat disimpan.",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: AppTheme.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.cardBorderColor, width: 1),
                        ),
                        child: _FormSection(controller: controller),
                      ),
                      const SizedBox(height: 16),
                      _SaveButton(controller: controller),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ScannerSection(controller: controller),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.cardBorderColor, width: 1),
                ),
                child: _FormSection(controller: controller),
              ),
              const SizedBox(height: 16),
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
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _openScanner(context, controller);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasCode ? AppTheme.stampRed : AppTheme.cardBorderColor,
              width: hasCode ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: hasCode
                      ? AppTheme.stampRed.withValues(alpha: 0.08)
                      : AppTheme.surfaceRecessed,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: hasCode ? AppTheme.stampRed.withValues(alpha: 0.3) : AppTheme.cardBorderColor,
                  ),
                ),
                child: Icon(
                  hasCode ? Icons.qr_code_2_rounded : Icons.qr_code_scanner_rounded,
                  color: hasCode ? AppTheme.stampRed : AppTheme.textPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: hasCode
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.stampRed,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "BARCODE TERDETEKSI",
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.stampRed,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            controller.scannedBarcode!,
                            style: GoogleFonts.jetBrainsMono(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Scan Barcode Barang",
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Ketuk untuk buka kamera pemindai (opsional)",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppTheme.textMuted,
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
                  color: AppTheme.stampRed,
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceRecessed,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.cardBorderColor),
                  ),
                  child: Text(
                    "SCAN →",
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
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
        Row(
          children: [
            Container(
              width: 3,
              height: 12,
              decoration: BoxDecoration(
                color: AppTheme.textPrimary,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "DETAIL PRODUK",
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _InputField(
          label: "NAMA BARANG",
          hint: "Contoh: Kuota Telkomsel 10GB",
          controller: controller.nameController,
        ),
        const SizedBox(height: 14),
        _InputField(
          label: "HARGA JUAL (RP)",
          hint: "0",
          controller: controller.priceController,
          keyboardType: TextInputType.number,
          isNumeric: true,
        ),
        const SizedBox(height: 14),
        _InputField(
          label: "JUMLAH STOK AWAL",
          hint: "0",
          controller: controller.stockController,
          keyboardType: TextInputType.number,
          isNumeric: true,
          onSubmit: (_) => _handleSave(context, controller),
        ),
        const SizedBox(height: 14),
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
  final bool isNumeric;
  final Function(String)? onSubmit;

  const _InputField({
    required this.label,
    this.hint,
    required this.controller,
    this.keyboardType,
    this.isNumeric = false,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontWeight: FontWeight.w700,
            fontSize: 10.5,
            color: AppTheme.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceRecessed,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.cardBorderColor),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            onSubmitted: onSubmit,
            style: isNumeric
                ? GoogleFonts.jetBrainsMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  )
                : GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.plusJakartaSans(
                color: AppTheme.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.normal,
              ),
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
            Text(
              "KATEGORI PRODUK",
              style: GoogleFonts.jetBrainsMono(
                fontWeight: FontWeight.w700,
                fontSize: 10.5,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            InkWell(
              onTap: () => _showAddCategoryDialog(context, controller),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceRecessed,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.cardBorderColor),
                ),
                child: Text(
                  "+ TAMBAH KATEGORI",
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
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
            color: AppTheme.surfaceRecessed,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.cardBorderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: controller.selectedCategory,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.cardBorderColor),
      ),
      title: Text(
        'Tambah Kategori Baru',
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15),
      ),
      content: TextField(
        controller: textCtrl,
        autofocus: true,
        style: GoogleFonts.plusJakartaSans(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Nama kategori...',
          hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 13),
          filled: true,
          fillColor: AppTheme.surfaceRecessed,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppTheme.cardBorderColor),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'Batal',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          onPressed: () async {
            final name = textCtrl.text.trim();
            if (name.isEmpty) return;
            final success = await controller.addCategory(name);
            if (ctx.mounted) Navigator.pop(ctx);
            if (success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Kategori "$name" berhasil ditambahkan', style: GoogleFonts.plusJakartaSans()),
                ),
              );
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Kategori sudah ada atau tidak valid', style: GoogleFonts.plusJakartaSans()),
                ),
              );
            }
          },
          child: Text(
            'SIMPAN',
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );
}

/* ================= SAVE BUTTON ================= */
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        onPressed: controller.isLoading
            ? null
            : () => _handleSave(context, controller),
        child: controller.isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "SIMPAN DATA BARANG",
                    style: GoogleFonts.jetBrainsMono(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                ],
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Data produk '${product.name}' berhasil disimpan",
          style: GoogleFonts.plusJakartaSans(),
        ),
      ),
    );
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.cardBorderColor),
      ),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.forestGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.forestGreen.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppTheme.forestGreen,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "PRODUK TERSIMPAN",
                        style: GoogleFonts.jetBrainsMono(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        "QR Code terenkripsi telah dibuat secara otomatis",
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceRecessed,
                border: Border.all(color: AppTheme.cardBorderColor),
                borderRadius: BorderRadius.circular(6),
              ),
              child: SizedBox(
                height: 140,
                width: 140,
                child: QrImageView(
                  data: SecurityService.encryptData(product.code),
                  size: 140,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              product.name,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              product.code,
              textAlign: TextAlign.center,
              style: GoogleFonts.jetBrainsMono(
                color: AppTheme.textSecondary,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppTheme.cardBorderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Text(
                      "TUTUP",
                      style: GoogleFonts.jetBrainsMono(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.print_rounded, size: 14),
                    label: Text(
                      "CETAK PDF",
                      style: GoogleFonts.jetBrainsMono(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          top: BorderSide(color: AppTheme.cardBorderColor, width: 1),
          left: BorderSide(color: AppTheme.cardBorderColor, width: 1),
          right: BorderSide(color: AppTheme.cardBorderColor, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Cari Data Barang Lama",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppTheme.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceRecessed,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.cardBorderColor),
            ),
            child: TextField(
              autofocus: true,
              onChanged: _search,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: "Ketik nama barang...",
                hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textSecondary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : (results.isEmpty
                    ? Center(
                        child: Text(
                          "Ketik minimal 2 huruf untuk mencari",
                          style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      )
                    : ListView.separated(
                        separatorBuilder: (_, _) => const Divider(height: 1, color: AppTheme.cardBorderColor),
                        itemCount: results.length,
                        itemBuilder: (_, i) {
                          final p = results[i];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            title: Text(
                              p.name,
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              "STOK: ${p.stock} • Rp ${p.price}",
                              style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppTheme.textSecondary),
                            ),
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
