import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_theme.dart';
import '../../models/receipt_custom_model.dart';
import '../../services/printer_service.dart';
import '../../services/receipt_custom_service.dart';

class ReceiptCustomizerPage extends StatefulWidget {
  const ReceiptCustomizerPage({super.key});

  @override
  State<ReceiptCustomizerPage> createState() => _ReceiptCustomizerPageState();
}

class _ReceiptCustomizerPageState extends State<ReceiptCustomizerPage> {
  ReceiptCustomModel _config = ReceiptCustomModel();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPrinting = false;
  int _activeTab = 0; // 0: Logo, 1: Header, 2: Transaksi, 3: Total, 4: Footer

  late TextEditingController _storeNameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _contactCtrl;
  late TextEditingController _headerNoteCtrl;
  late TextEditingController _cashierNameCtrl;
  late TextEditingController _footerMsgCtrl;
  late TextEditingController _warrantyCtrl;
  late TextEditingController _socmedCtrl;
  late TextEditingController _taxPercentCtrl;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadConfig();
  }

  void _initControllers() {
    _storeNameCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _contactCtrl = TextEditingController();
    _headerNoteCtrl = TextEditingController();
    _cashierNameCtrl = TextEditingController();
    _footerMsgCtrl = TextEditingController();
    _warrantyCtrl = TextEditingController();
    _socmedCtrl = TextEditingController();
    _taxPercentCtrl = TextEditingController();
  }

  void _updateControllers() {
    _storeNameCtrl.text = _config.storeName;
    _addressCtrl.text = _config.storeAddress;
    _contactCtrl.text = _config.storeContact;
    _headerNoteCtrl.text = _config.headerNote;
    _cashierNameCtrl.text = _config.cashierName;
    _footerMsgCtrl.text = _config.footerMessage;
    _warrantyCtrl.text = _config.warrantyNotice;
    _socmedCtrl.text = _config.socialMediaText;
    _taxPercentCtrl.text = _config.taxPercent.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _addressCtrl.dispose();
    _contactCtrl.dispose();
    _headerNoteCtrl.dispose();
    _cashierNameCtrl.dispose();
    _footerMsgCtrl.dispose();
    _warrantyCtrl.dispose();
    _socmedCtrl.dispose();
    _taxPercentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final cfg = await ReceiptCustomService.instance.getConfig();
    setState(() {
      _config = cfg;
      _isLoading = false;
      _updateControllers();
    });
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    // Sinkronkan text field ke model
    _config.storeName = _storeNameCtrl.text.trim();
    _config.storeAddress = _addressCtrl.text.trim();
    _config.storeContact = _contactCtrl.text.trim();
    _config.headerNote = _headerNoteCtrl.text.trim();
    _config.cashierName = _cashierNameCtrl.text.trim();
    _footerMsgCtrl.text = _footerMsgCtrl.text.trim();
    _config.warrantyNotice = _warrantyCtrl.text.trim();
    _config.socialMediaText = _socmedCtrl.text.trim();
    _config.taxPercent = double.tryParse(_taxPercentCtrl.text.trim()) ?? 11.0;

    final success = await ReceiptCustomService.instance.saveConfig(_config);
    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Struktur struk 58mm berhasil disimpan!' : 'Gagal menyimpan pengaturan struk.',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: success ? AppTheme.primaryDark : AppTheme.stampRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  Future<void> _pickLogo() async {
    final path = await ReceiptCustomService.instance.pickLogoImage();
    if (path != null && mounted) {
      setState(() {
        _config.logoPath = path;
        _config.showLogo = true;
      });
    }
  }

  Future<void> _clearLogo() async {
    await ReceiptCustomService.instance.clearLogo(_config);
    if (mounted) {
      setState(() {
        _config.logoPath = null;
      });
    }
  }

  Future<void> _testPrint() async {
    setState(() => _isPrinting = true);
    try {
      final printer = PrinterService();
      final isConn = await printer.checkConnection();
      if (!isConn) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Printer Bluetooth belum terhubung.', style: GoogleFonts.plusJakartaSans()),
            backgroundColor: AppTheme.stampRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        );
        return;
      }
      await printer.printTestSampleStruk(_config);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uji cetak struk 58mm terkirim ke printer!', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: AppTheme.forestGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mencetak: $e', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: AppTheme.stampRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryDark, strokeWidth: 2),
        ),
      );
    }

    final isLandscape = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
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
        title: Text(
          "Kustomisasi Struk 58mm",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: AppTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Reset ke Standar",
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceRecessed,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.cardBorderColor),
              ),
              child: const Icon(Icons.restore_rounded, color: AppTheme.textPrimary, size: 16),
            ),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppTheme.cardBorderColor),
                  ),
                  title: Text("Reset Format Struk?", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15)),
                  content: Text("Kembalikan format struk ke pengaturan awal standar toko?", style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppTheme.textSecondary)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text("Batal", style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text("RESET", style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700, fontSize: 11)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                final def = await ReceiptCustomService.instance.resetToDefault();
                setState(() {
                  _config = def;
                  _updateControllers();
                });
              }
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: isLandscape ? _buildLandscapeLayout() : _buildPortraitLayout(),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildPortraitLayout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildReceiptPaperSimulator(),
          const SizedBox(height: 16),
          _buildCategoryPills(),
          const SizedBox(height: 14),
          _buildActiveSettingsSection(),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Kolom Kiri: Simulator Kertas 58mm
        Expanded(
          flex: 45,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: _buildReceiptPaperSimulator(),
          ),
        ),

        // Garis Pembatas
        Container(width: 1, color: AppTheme.cardBorderColor),

        // Kolom Kanan: Pengaturan Form & Opsi
        Expanded(
          flex: 55,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategoryPills(),
                const SizedBox(height: 14),
                _buildActiveSettingsSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- KARTU SIMULATOR KERTAS STRUK THERMAL 58MM ---
  Widget _buildReceiptPaperSimulator() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 310),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.cardBorderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pita Bergerigi Bagian Atas
              CustomPaint(
                size: const Size(double.infinity, 8),
                painter: const _SerratedEdgePainter(isTop: true),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Label Badge 58mm
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceRecessed,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.cardBorderColor),
                        ),
                        child: Text(
                          "PREVIEW KERTAS 58MM • 32 KOLOM",
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 1. LOGO: TOP
                    if (_config.showLogo && _config.logoPosition == ReceiptLogoPosition.top)
                      _buildPreviewLogo(),

                    // 2. HEADER
                    _buildPreviewHeader(),

                    // 3. LOGO: AFTER HEADER
                    if (_config.showLogo && _config.logoPosition == ReceiptLogoPosition.afterHeader)
                      _buildPreviewLogo(),

                    // 4. INFO TRANSAKSI
                    _buildPreviewInvoiceInfo(),

                    // 5. LOGO: BEFORE ITEMS
                    if (_config.showLogo && _config.logoPosition == ReceiptLogoPosition.beforeItems)
                      _buildPreviewLogo(),

                    // 6. DAFTAR ITEM
                    _buildPreviewItems(),

                    // 7. TOTAL & PEMBAYARAN
                    _buildPreviewTotals(),

                    // 8. LOGO: AFTER TOTAL
                    if (_config.showLogo && _config.logoPosition == ReceiptLogoPosition.afterTotal)
                      _buildPreviewLogo(),

                    // 9. FOOTER & QR
                    _buildPreviewFooter(),

                    // 10. LOGO: BOTTOM
                    if (_config.showLogo && _config.logoPosition == ReceiptLogoPosition.bottom)
                      _buildPreviewLogo(),
                  ],
                ),
              ),

              // Pita Bergerigi Bagian Bawah
              CustomPaint(
                size: const Size(double.infinity, 8),
                painter: const _SerratedEdgePainter(isTop: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewLogo() {
    Alignment align = Alignment.center;
    if (_config.logoAlignment == ReceiptLogoAlign.left) align = Alignment.centerLeft;
    if (_config.logoAlignment == ReceiptLogoAlign.right) align = Alignment.centerRight;

    double displayWidth = 90;
    if (_config.logoSize == ReceiptLogoSize.small) displayWidth = 60;
    if (_config.logoSize == ReceiptLogoSize.full) displayWidth = 220;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: align,
        child: _config.logoPath != null && File(_config.logoPath!).existsSync()
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(
                  File(_config.logoPath!),
                  width: displayWidth,
                  fit: BoxFit.contain,
                ),
              )
            : Container(
                width: displayWidth,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceRecessed,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.cardBorderColor),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.store_rounded, size: 14, color: AppTheme.textPrimary),
                      const SizedBox(width: 4),
                      Text(
                        "LOGO TOKO",
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPreviewHeader() {
    double titleSize = 13;
    if (_config.storeNameSize == 'large') titleSize = 15;
    if (_config.storeNameSize == 'extra_large') titleSize = 18;

    return Column(
      children: [
        Text(
          _config.storeName.isNotEmpty ? _config.storeName : "NANDA CELL",
          textAlign: TextAlign.center,
          style: GoogleFonts.jetBrainsMono(
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        if (_config.showHeaderNote && _config.headerNote.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            _config.headerNote,
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(fontSize: 9.5, color: AppTheme.textSecondary),
          ),
        ],
        if (_config.showAddress && _config.storeAddress.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            _config.storeAddress,
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(fontSize: 9.5, color: AppTheme.textSecondary),
          ),
        ],
        if (_config.showContact && _config.storeContact.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            _config.storeContact,
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(fontSize: 9.5, color: AppTheme.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _buildPreviewInvoiceInfo() {
    return Column(
      children: [
        const SizedBox(height: 6),
        Text(
          _config.dividerStyle.pattern,
          textAlign: TextAlign.center,
          maxLines: 1,
          style: GoogleFonts.jetBrainsMono(fontSize: 9.5, color: AppTheme.textMuted),
        ),
        if (_config.showInvoiceNumber)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("No : INV-20261101-001", style: GoogleFonts.jetBrainsMono(fontSize: 9.5)),
            ],
          ),
        if (_config.showDate || _config.showTime)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Tgl: 01-11-2026 14:30", style: GoogleFonts.jetBrainsMono(fontSize: 9.5)),
            ],
          ),
        if (_config.showCashierName && _config.cashierName.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Ksr: ${_config.cashierName}", style: GoogleFonts.jetBrainsMono(fontSize: 9.5)),
            ],
          ),
        Text(
          _config.dividerStyle.pattern,
          textAlign: TextAlign.center,
          maxLines: 1,
          style: GoogleFonts.jetBrainsMono(fontSize: 9.5, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildPreviewItems() {
    return Column(
      children: [
        _previewItemRow("KUOTA TELKOMSEL 10GB", "1 x 35.000", "35.000"),
        const SizedBox(height: 4),
        _previewItemRow("KABEL DATA TYPE-C", "1 x 25.000", "25.000"),
        const SizedBox(height: 4),
        _previewItemRow("TEMPERED GLASS BENING", "1 x 15.000", "15.000"),
        const SizedBox(height: 6),
        Text(
          _config.dividerStyle.pattern,
          textAlign: TextAlign.center,
          maxLines: 1,
          style: GoogleFonts.jetBrainsMono(fontSize: 9.5, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _previewItemRow(String name, String qtyAndPrice, String subtotal) {
    if (_config.compactItemRows) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.jetBrainsMono(fontSize: 9.5, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Text(subtotal, style: GoogleFonts.jetBrainsMono(fontSize: 9.5, fontWeight: FontWeight.bold)),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.jetBrainsMono(fontSize: 9.5, fontWeight: FontWeight.bold),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                qtyAndPrice,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(width: 8),
            Text(subtotal, style: GoogleFonts.jetBrainsMono(fontSize: 9.5, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildPreviewTotals() {
    return Column(
      children: [
        if (_config.showSubtotalRow && _config.showTax) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Subtotal", style: GoogleFonts.jetBrainsMono(fontSize: 9.5)),
              Text("67.568", style: GoogleFonts.jetBrainsMono(fontSize: 9.5)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("PPN (${_config.taxPercent.toStringAsFixed(0)}%)", style: GoogleFonts.jetBrainsMono(fontSize: 9.5)),
              Text("7.432", style: GoogleFonts.jetBrainsMono(fontSize: 9.5)),
            ],
          ),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("TOTAL", style: GoogleFonts.jetBrainsMono(fontSize: 11.5, fontWeight: FontWeight.w800)),
            Text("Rp 75.000", style: GoogleFonts.jetBrainsMono(fontSize: 11.5, fontWeight: FontWeight.w800)),
          ],
        ),
        if (_config.showCashAndChange) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Tunai", style: GoogleFonts.jetBrainsMono(fontSize: 9)),
              Text("Rp 100.000", style: GoogleFonts.jetBrainsMono(fontSize: 9)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Kembali", style: GoogleFonts.jetBrainsMono(fontSize: 9)),
              Text("Rp 25.000", style: GoogleFonts.jetBrainsMono(fontSize: 9)),
            ],
          ),
        ],
        const SizedBox(height: 6),
        Text(
          _config.dividerStyle.pattern,
          textAlign: TextAlign.center,
          maxLines: 1,
          style: GoogleFonts.jetBrainsMono(fontSize: 9.5, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildPreviewFooter() {
    return Column(
      children: [
        if (_config.showFooterMessage && _config.footerMessage.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            _config.footerMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ],
        if (_config.showSocialMedia && _config.socialMediaText.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            _config.socialMediaText,
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(fontSize: 8.5, color: AppTheme.textSecondary),
          ),
        ],
        if (_config.showWarrantyNotice && _config.warrantyNotice.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            "KETENTUAN:",
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(fontSize: 8.5, fontWeight: FontWeight.bold),
          ),
          Text(
            _config.warrantyNotice,
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(fontSize: 8.5, color: AppTheme.textSecondary),
          ),
        ],
        if (_config.showInvoiceQr) ...[
          const SizedBox(height: 6),
          Center(
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.cardBorderColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.qr_code_2_rounded, size: 36, color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "Scan Struk",
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(fontSize: 8, color: AppTheme.textMuted),
          ),
        ],
      ],
    );
  }

  // --- KATEGORI PENGATURAN BERBENTUK BADGE TEKSTUR TACTILE ---
  Widget _buildCategoryPills() {
    final tabs = [
      {'code': 'LOGO', 'label': 'Logo & Letak', 'icon': Icons.image_rounded},
      {'code': 'HEADER', 'label': 'Info Toko', 'icon': Icons.storefront_rounded},
      {'code': 'NOTA', 'label': 'Nota & Baris', 'icon': Icons.receipt_rounded},
      {'code': 'TOTAL', 'label': 'Harga & Pajak', 'icon': Icons.payments_rounded},
      {'code': 'FOOTER', 'label': 'Footer & QR', 'icon': Icons.qr_code_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSelected = _activeTab == i;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _activeTab = i);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryDark : AppTheme.surfaceRecessed,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryDark : AppTheme.cardBorderColor,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withValues(alpha: 0.18) : Colors.white,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : AppTheme.cardBorderColor,
                        ),
                      ),
                      child: Text(
                        tabs[i]['code'] as String,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tabs[i]['label'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- FORM KONTROL BERDASARKAN KATEGORI AKTIF ---
  Widget _buildActiveSettingsSection() {
    switch (_activeTab) {
      case 0:
        return _buildLogoSettingsCard();
      case 1:
        return _buildHeaderSettingsCard();
      case 2:
        return _buildInvoiceSettingsCard();
      case 3:
        return _buildTotalSettingsCard();
      case 4:
        return _buildFooterSettingsCard();
      default:
        return const SizedBox.shrink();
    }
  }

  // TAB 1: LOGO & POSISI
  Widget _buildLogoSettingsCard() {
    return _buildSettingsGroupContainer(
      title: "KUSTOMISASI LOGO TOKO",
      subtitle: "Unggah gambar logo dan tentukan posisi letaknya di struk",
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text("Tampilkan Logo Visual", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
          subtitle: Text("Aktifkan pencetakan logo pada struk 58mm", style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary)),
          value: _config.showLogo,
          activeTrackColor: AppTheme.primaryDark,
          onChanged: (val) => setState(() => _config.showLogo = val),
        ),
        const Divider(height: 16, color: AppTheme.cardBorderColor),

        // Preview & Tombol Upload
        Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.surfaceRecessed,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.cardBorderColor),
              ),
              child: _config.logoPath != null && File(_config.logoPath!).existsSync()
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(File(_config.logoPath!), fit: BoxFit.contain),
                    )
                  : const Icon(Icons.add_photo_alternate_rounded, size: 24, color: AppTheme.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      elevation: 0,
                    ),
                    onPressed: _pickLogo,
                    icon: const Icon(Icons.file_upload_outlined, size: 15),
                    label: Text("PILIH GAMBAR LOGO", style: GoogleFonts.jetBrainsMono(fontSize: 10.5, fontWeight: FontWeight.w800)),
                  ),
                  if (_config.logoPath != null) ...[
                    const SizedBox(height: 4),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.stampRed,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: _clearLogo,
                      icon: const Icon(Icons.delete_outline, size: 14),
                      label: Text("Hapus Logo Gambar", style: GoogleFonts.plusJakartaSans(fontSize: 11)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Posisi Logo di Struk
        Text(
          "POSISI PELETAKAN LOGO:",
          style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w800, fontSize: 10, color: AppTheme.textSecondary, letterSpacing: 0.5),
        ),
        const SizedBox(height: 6),
        ...ReceiptLogoPosition.values.map((pos) {
          final isSelected = _config.logoPosition == pos;
          return Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => setState(() => _config.logoPosition = pos),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.surfaceRecessed : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryDark : AppTheme.cardBorderColor,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      size: 15,
                      color: isSelected ? AppTheme.primaryDark : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pos.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 14),
        // Perataan Logo
        Text(
          "Perataan Posisi Horizontal:",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: ReceiptLogoAlign.values.map((al) {
            final isSelected = _config.logoAlignment == al;
            return ChoiceChip(
              label: Text(al.label, style: GoogleFonts.plusJakartaSans(fontSize: 11)),
              selected: isSelected,
              selectedColor: AppTheme.primaryDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              onSelected: (val) {
                if (val) setState(() => _config.logoAlignment = al);
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 14),
        // Ukuran Logo
        Text(
          "Ukuran Cetak Logo 58mm:",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: ReceiptLogoSize.values.map((sz) {
            final isSelected = _config.logoSize == sz;
            return ChoiceChip(
              label: Text(sz.label, style: GoogleFonts.plusJakartaSans(fontSize: 11)),
              selected: isSelected,
              selectedColor: AppTheme.primaryDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              onSelected: (val) {
                if (val) setState(() => _config.logoSize = sz);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // TAB 2: IDENTITAS & HEADER TOKO
  Widget _buildHeaderSettingsCard() {
    return _buildSettingsGroupContainer(
      title: "IDENTITAS & HEADER TOKO",
      subtitle: "Nama, alamat, kontak, dan tagline toko",
      children: [
        _buildTextField("NAMA TOKO", _storeNameCtrl, "Contoh: NANDA CELL POS"),
        const SizedBox(height: 12),
        Text("UKURAN HURUF NAMA TOKO:", style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildFontOption("Normal", "normal"),
            _buildFontOption("Besar (2x)", "large"),
            _buildFontOption("Maksimal (3x)", "extra_large"),
          ],
        ),
        const SizedBox(height: 14),
        _buildSwitchWithField(
          label: "Tampilkan Tagline / Slogan",
          value: _config.showHeaderNote,
          onChanged: (v) => setState(() => _config.showHeaderNote = v),
          child: _buildTextField("SLOGAN TOKO", _headerNoteCtrl, "Contoh: Pusat Aksesoris & Servis HP"),
        ),
        const SizedBox(height: 12),
        _buildSwitchWithField(
          label: "Tampilkan Alamat Toko",
          value: _config.showAddress,
          onChanged: (v) => setState(() => _config.showAddress = v),
          child: _buildTextField("ALAMAT TOKO", _addressCtrl, "Contoh: Jl. Diponegoro No. 88"),
        ),
        const SizedBox(height: 12),
        _buildSwitchWithField(
          label: "Tampilkan Kontak / Telepon",
          value: _config.showContact,
          onChanged: (v) => setState(() => _config.showContact = v),
          child: _buildTextField("KONTAK TOKO", _contactCtrl, "Contoh: WhatsApp: 0812-3456-7890"),
        ),
      ],
    );
  }

  // TAB 3: NOTA & GARIS PEMISAH
  Widget _buildInvoiceSettingsCard() {
    return _buildSettingsGroupContainer(
      title: "INFORMASI TRANSAKSI & PEMISAH",
      subtitle: "Pengaturan nota, kasir, waktu, dan format daftar item",
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text("Tampilkan No Nota Transaksi", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
          value: _config.showInvoiceNumber,
          activeTrackColor: AppTheme.primaryDark,
          onChanged: (v) => setState(() => _config.showInvoiceNumber = v),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text("Tampilkan Tanggal Transaksi", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
          value: _config.showDate,
          activeTrackColor: AppTheme.primaryDark,
          onChanged: (v) => setState(() => _config.showDate = v),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text("Tampilkan Jam Transaksi", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
          value: _config.showTime,
          activeTrackColor: AppTheme.primaryDark,
          onChanged: (v) => setState(() => _config.showTime = v),
        ),
        const Divider(height: 14, color: AppTheme.cardBorderColor),
        _buildSwitchWithField(
          label: "Tampilkan Nama Operator / Kasir",
          value: _config.showCashierName,
          onChanged: (v) => setState(() => _config.showCashierName = v),
          child: _buildTextField("NAMA OPERATOR / KASIR", _cashierNameCtrl, "Contoh: Kasir Utama"),
        ),
        const SizedBox(height: 14),
        Text("GAYA GARIS PEMISAH (32 CHARS):", style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        ...ReceiptDividerStyle.values.map((div) {
          final isSelected = _config.dividerStyle == div;
          return Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => setState(() => _config.dividerStyle = div),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.surfaceRecessed : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryDark : AppTheme.cardBorderColor,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      size: 15,
                      color: isSelected ? AppTheme.primaryDark : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        div.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      div.pattern.substring(0, 10),
                      style: GoogleFonts.jetBrainsMono(fontSize: 9.5, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text("Mode Baris Item Ringkas", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
          subtitle: Text("1 baris per barang untuk menghemat kertas struk", style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary)),
          value: _config.compactItemRows,
          activeTrackColor: AppTheme.primaryDark,
          onChanged: (v) => setState(() => _config.compactItemRows = v),
        ),
      ],
    );
  }

  // TAB 4: TOTAL & RINCIAN HARGA
  Widget _buildTotalSettingsCard() {
    return _buildSettingsGroupContainer(
      title: "RINCIAN HARGA, PAJAK & PEMBAYARAN",
      subtitle: "Pengaturan subtotal, PPN, dan rincian kembalian",
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text("Tampilkan Rincian Subtotal", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
          value: _config.showSubtotalRow,
          activeTrackColor: AppTheme.primaryDark,
          onChanged: (v) => setState(() => _config.showSubtotalRow = v),
        ),
        const SizedBox(height: 6),
        _buildSwitchWithField(
          label: "Hitung & Tampilkan Pajak (PPN)",
          value: _config.showTax,
          onChanged: (v) => setState(() => _config.showTax = v),
          child: _buildTextField("TARIF PAJAK (%)", _taxPercentCtrl, "11"),
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text("Tampilkan Nominal Tunai & Kembalian", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
          subtitle: Text("Mencetak uang diserahkan dan sisa kembalian pelanggan", style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary)),
          value: _config.showCashAndChange,
          activeTrackColor: AppTheme.primaryDark,
          onChanged: (v) => setState(() => _config.showCashAndChange = v),
        ),
      ],
    );
  }

  // TAB 5: FOOTER & QR CODE
  Widget _buildFooterSettingsCard() {
    return _buildSettingsGroupContainer(
      title: "FOOTER STRUK & KODE QR",
      subtitle: "Pesan ucapan terima kasih, garansi, sosial media, & QR nota",
      children: [
        _buildSwitchWithField(
          label: "Pesan Penutup Struk",
          value: _config.showFooterMessage,
          onChanged: (v) => setState(() => _config.showFooterMessage = v),
          child: _buildTextField("PESAN PENUTUP", _footerMsgCtrl, "Terima Kasih Atas Kunjungan Anda!"),
        ),
        const SizedBox(height: 12),
        _buildSwitchWithField(
          label: "Ketentuan Garansi Toko",
          value: _config.showWarrantyNotice,
          onChanged: (v) => setState(() => _config.showWarrantyNotice = v),
          child: _buildTextField("KETENTUAN GARANSI", _warrantyCtrl, "Klaim garansi wajib menunjukkan struk ini."),
        ),
        const SizedBox(height: 12),
        _buildSwitchWithField(
          label: "Akun Media Sosial / Website",
          value: _config.showSocialMedia,
          onChanged: (v) => setState(() => _config.showSocialMedia = v),
          child: _buildTextField("MEDIA SOSIAL", _socmedCtrl, "Follow IG: @nandapos_id"),
        ),
        const SizedBox(height: 12),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text("Cetak QR Code Nomor Nota", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
          subtitle: Text("Mencetak barcode QR di akhir struk untuk scan retur", style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary)),
          value: _config.showInvoiceQr,
          activeTrackColor: AppTheme.primaryDark,
          onChanged: (v) => setState(() => _config.showInvoiceQr = v),
        ),
      ],
    );
  }

  // --- WIDGET HELPER FORM ---
  Widget _buildSettingsGroupContainer({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.cardBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(
            title,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.cardBorderColor),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceRecessed,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.cardBorderColor),
          ),
          child: TextField(
            controller: ctrl,
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchWithField({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(label, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
          value: value,
          activeTrackColor: AppTheme.primaryDark,
          onChanged: onChanged,
        ),
        if (value) ...[
          const SizedBox(height: 5),
          child,
        ],
      ],
    );
  }

  Widget _buildFontOption(String label, String value) {
    final isSelected = _config.storeNameSize == value;
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.jetBrainsMono(fontSize: 11)),
      selected: isSelected,
      selectedColor: AppTheme.primaryDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textPrimary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      onSelected: (val) {
        if (val) setState(() => _config.storeNameSize = value);
      },
    );
  }

  // --- FLOATING BOTTOM ACTION BAR ---
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.cardBorderColor, width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.cardBorderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                ),
                onPressed: _isPrinting ? null : _testPrint,
                icon: _isPrinting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textPrimary),
                      )
                    : const Icon(Icons.print_outlined, size: 15, color: AppTheme.textPrimary),
                label: Text(
                  _isPrinting ? "Mencetak..." : "Uji Cetak 58mm",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 11, color: AppTheme.textPrimary),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 6,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  elevation: 0,
                ),
                onPressed: _isSaving ? null : _saveConfig,
                icon: _isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline_rounded, size: 15),
                label: Text(
                  _isSaving ? "Menyimpan..." : "Simpan Desain Struk",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter untuk gerigi tepi sobekan kertas thermal receipt
class _SerratedEdgePainter extends CustomPainter {
  final bool isTop;
  const _SerratedEdgePainter({required this.isTop});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.surfaceRecessed
      ..style = PaintingStyle.fill;

    final path = Path();
    const toothWidth = 8.0;
    final toothHeight = size.height;
    final count = (size.width / toothWidth).ceil();

    if (isTop) {
      path.moveTo(0, size.height);
      for (int i = 0; i < count; i++) {
        final x = i * toothWidth;
        path.lineTo(x + toothWidth / 2, 0);
        path.lineTo(x + toothWidth, size.height);
      }
      path.close();
    } else {
      path.moveTo(0, 0);
      for (int i = 0; i < count; i++) {
        final x = i * toothWidth;
        path.lineTo(x + toothWidth / 2, toothHeight);
        path.lineTo(x + toothWidth, 0);
      }
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
