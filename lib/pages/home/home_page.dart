import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;

import '../../config/app_config.dart';
import '../../config/app_theme.dart';
import '../../controllers/server_status_controller.dart';
import '../../controllers/tablet_mode_controller.dart';
import '../../utils/permission_helper.dart';
import '../product/add_product_page.dart';
import '../product/product_list_page.dart';
import '../cashier/cashier_page.dart';
import '../printing/bulk_print_page.dart';
import '../history/history_page.dart';
import '../settings/settings_page.dart';
import '../report/report_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _permissionRequested = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  void _requestPermissions() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _permissionRequested) return;
      _permissionRequested = true;
      PermissionHelper.requestAppPermissions(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = context.watch<TabletModeController>().isTabletLayout(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      drawer: _buildDrawer(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await context.read<ServerStatusController>().checkStatus();
            HapticFeedback.lightImpact();
          },
          color: AppTheme.primaryColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(context),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: SliverToBoxAdapter(
                  child: isTablet
                      ? _buildTabletMainContent(context)
                      : _buildPortraitMainContent(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- PORTRAIT CONTENT ---
  Widget _buildPortraitMainContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HARDWARE HERO CONSOLE (CARBON MONOLITH)
        _HeroCashierCard(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CashierPage()),
            );
          },
        ),
        const SizedBox(height: 20),

        // SECTION HEADER (ARCHITECTURAL LABEL)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 12,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  "MODUL OPERASIONAL TOKO",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.surfaceRecessed,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.cardBorderColor),
              ),
              child: Text(
                "OFFLINE MODE",
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
        const SizedBox(height: 10),

        // ASYMMETRIC BENTO GRID (ARCHITECTURAL TILES)
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.25,
          children: const [
            _TactileMenuCard(
              title: "Katalog Produk",
              subtitle: "Kelola stok & harga",
              codeTag: "SKU-MGR",
              icon: Icons.inventory_2_outlined,
              page: ProductListPage(),
            ),
            _TactileMenuCard(
              title: "Tambah Produk",
              subtitle: "Item baru & barcode",
              codeTag: "NEW-ITEM",
              icon: Icons.add_box_outlined,
              page: AddProductPage(),
            ),
            _TactileMenuCard(
              title: "Riwayat Nota",
              subtitle: "Arsip struk tersimpan",
              codeTag: "LOG-TRX",
              icon: Icons.receipt_long_outlined,
              page: HistoryPage(),
            ),
            _TactileMenuCard(
              title: "Label Barcode",
              subtitle: "Cetak stiker massal",
              codeTag: "LBL-PRT",
              icon: Icons.qr_code_2_rounded,
              page: BulkPrintPage(),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // FINANCIAL LEDGER BANNER
        _AnalyticsBannerCard(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportPage()),
            );
          },
        ),
        const SizedBox(height: 24),

        // MINIMAL FOOTER
        Center(
          child: Text(
            "${Config.appName.toUpperCase()}  //  STANDALONE V${Config.appVersion}",
            style: GoogleFonts.jetBrainsMono(
              color: AppTheme.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  // --- TABLET HORIZONTAL CONTENT ---
  Widget _buildTabletMainContent(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Hero Console + Analytics Card
            Expanded(
              flex: 46,
              child: Column(
                children: [
                  _HeroCashierCard(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CashierPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _AnalyticsBannerCard(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReportPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Right Column: 4 Menu Cards (2x2 grid)
            Expanded(
              flex: 54,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(width: 3, height: 12, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                "OPERASIONAL & MANAJEMEN",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceRecessed,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.cardBorderColor),
                        ),
                        child: Text(
                          "TABLET ENGINE",
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.45,
                    children: const [
                      _TactileMenuCard(
                        title: "Katalog Produk",
                        subtitle: "Kelola stok & harga",
                        codeTag: "SKU-MGR",
                        icon: Icons.inventory_2_outlined,
                        page: ProductListPage(),
                      ),
                      _TactileMenuCard(
                        title: "Tambah Produk",
                        subtitle: "Item baru & barcode",
                        codeTag: "NEW-ITEM",
                        icon: Icons.add_box_outlined,
                        page: AddProductPage(),
                      ),
                      _TactileMenuCard(
                        title: "Riwayat Nota",
                        subtitle: "Arsip struk tersimpan",
                        codeTag: "LOG-TRX",
                        icon: Icons.receipt_long_outlined,
                        page: HistoryPage(),
                      ),
                      _TactileMenuCard(
                        title: "Label Barcode",
                        subtitle: "Cetak stiker massal",
                        codeTag: "LBL-PRT",
                        icon: Icons.qr_code_2_rounded,
                        page: BulkPrintPage(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            "${Config.appName.toUpperCase()}  //  STANDALONE V${Config.appVersion}",
            style: GoogleFonts.jetBrainsMono(
              color: AppTheme.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  // --- MASTHEAD HEADER ---
  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    String dateStr;
    try {
      dateStr = DateFormat('EEE, dd MMM yyyy', 'id_ID').format(now).toUpperCase();
    } catch (_) {
      dateStr = "${now.day}/${now.month}/${now.year}";
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(color: AppTheme.cardBorderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceRecessed,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.cardBorderColor),
                ),
                child: const Icon(
                  Icons.menu_rounded,
                  color: AppTheme.primaryColor,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      "NANDA CELL",
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.primaryColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceRecessed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "POS OFFLINE",
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: GoogleFonts.jetBrainsMono(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const _TactileStatusBadge(),
        ],
      ),
    );
  }

  // --- ARCHITECTURAL DRAWER ---
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                border: Border(
                  bottom: BorderSide(color: Color(0xFF28292E), width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF23252B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF33353E)),
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "Nanda Cell POS",
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Sistem Kasir & Inventori Lokal",
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  _DrawerItem(
                    indexCode: "01",
                    icon: Icons.tune_rounded,
                    title: "Pengaturan Sistem",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
                    },
                  ),
                ],
              ),
            ),

            const Spacer(),
            const Divider(color: AppTheme.cardBorderColor, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Versi ${Config.appVersion} // Standalone DB",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.jetBrainsMono(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- HERO HARDWARE CONSOLE CARD ---
class _HeroCashierCard extends StatelessWidget {
  final VoidCallback onTap;
  const _HeroCashierCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF28292E), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF23252B),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF33353E)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.successColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "REG-01 // READY",
                            style: GoogleFonts.jetBrainsMono(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "TERMINAL KASIR",
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Proses transaksi barcode, hitung kembalian & cetak nota fisik 58mm",
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 42,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.point_of_sale_rounded, color: AppTheme.primaryColor, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "BUKA TERMINAL KASIR  →",
                          style: GoogleFonts.jetBrainsMono(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- FINANCIAL LEDGER BANNER ---
class _AnalyticsBannerCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AnalyticsBannerCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cardBorderColor, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceRecessed,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.cardBorderColor),
                  ),
                  child: const Icon(
                    Icons.query_stats_rounded,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Laporan & Analisis Penjualan",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Rekap omset, tren diagram garis & ekspor PDF/Excel",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_outward_rounded,
                  size: 18,
                  color: AppTheme.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- TACTILE MENU CARD (ARCHITECTURAL 8PX) ---
class _TactileMenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String codeTag;
  final IconData icon;
  final Widget page;

  const _TactileMenuCard({
    required this.title,
    required this.subtitle,
    required this.codeTag,
    required this.icon,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cardBorderColor, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(context, MaterialPageRoute(builder: (_) => page));
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceRecessed,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.cardBorderColor),
                      ),
                      child: Icon(icon, color: AppTheme.primaryColor, size: 17),
                    ),
                    Text(
                      codeTag,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
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

// --- DRAWER ITEM ---
class _DrawerItem extends StatelessWidget {
  final String indexCode;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.indexCode,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.surfaceRecessed,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 16),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        trailing: Text(
          indexCode,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMuted,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

// --- TACTILE STATUS BADGE ---
class _TactileStatusBadge extends StatelessWidget {
  const _TactileStatusBadge();

  @override
  Widget build(BuildContext context) {
    return Consumer<ServerStatusController>(
      builder: (_, controller, _) {
        final isOnline = controller.isOnline;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isOnline ? const Color(0xFFF0FDF4) : AppTheme.surfaceRecessed,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isOnline ? const Color(0xFFBBF7D0) : AppTheme.cardBorderColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline ? AppTheme.successColor : AppTheme.textMuted,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isOnline ? "SYNC ON" : "LOCAL",
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: isOnline ? AppTheme.successColor : AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
