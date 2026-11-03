import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/sales_analytics_model.dart';
import '../../services/sales_insight_engine.dart';
import '../../services/sales_analytics_export_service.dart';
import '../../controllers/tablet_mode_controller.dart';
import '../../utils/currency_format.dart';
import '../../config/app_theme.dart';
import 'widgets/sales_chart_widget.dart';

class SalesAnalyticsDashboardPage extends StatefulWidget {
  final SalesAnalyticsSummary summary;

  const SalesAnalyticsDashboardPage({
    super.key,
    required this.summary,
  });

  @override
  State<SalesAnalyticsDashboardPage> createState() =>
      _SalesAnalyticsDashboardPageState();
}

class _SalesAnalyticsDashboardPageState
    extends State<SalesAnalyticsDashboardPage> {
  String _activeChartType = 'bar'; // 'bar' | 'line'
  int _bottomTab = 0; // 0: Rincian Angka, 1: Produk Terlaris

  late final SalesInsightsResult _insights;

  @override
  void initState() {
    super.initState();
    _insights = widget.summary.insights ??
        SalesInsightEngine.generateInsights(summary: widget.summary);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = context.watch<TabletModeController>().isTabletLayout(context);

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
        title: Row(
          children: [
            Text(
              'Dashboard Analitik',
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
                isTablet ? 'TABLET-POS' : 'SALES-INTEL',
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
                Icons.file_download_rounded,
                size: 16,
                color: AppTheme.textPrimary,
              ),
            ),
            tooltip: 'Ekspor Hasil Analisis (PDF / Excel / PPT)',
            onPressed: () =>
                SalesAnalyticsExportService.showExportModal(context, widget.summary),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: isTablet
          ? _buildTabletDashboardLayout()
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. HERO PERIODE BANNER
                  _buildHeroBanner(),
                  const SizedBox(height: 12),

                  // BAR EKSPOR CEPAT (PDF, EXCEL, PPT)
                  _buildQuickExportBar(),
                  const SizedBox(height: 14),

                  // 2. KARTU INSIGHT BERBASIS ALGORITMA CERDAS
                  _buildAlgorithmicInsightsCard(),
                  const SizedBox(height: 14),

                  // 3. 4 KARTU KPI METRIK UTAMA
                  _buildKpiMetricsGrid(),
                  const SizedBox(height: 14),

                  // 4. BAGIAN GRAFIK (DIAGRAM BATANG & GARIS)
                  _buildChartSection(),
                  const SizedBox(height: 14),

                  // 5. DETAIL RINCIAN & PRODUK TERLARIS (TABBED)
                  _buildDetailsTabSection(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // =========================================================================
  // TABLET HORIZONTAL LAYOUT
  // =========================================================================
  Widget _buildTabletDashboardLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. WIDESCREEN HERO BANNER
          _buildTabletHeroBanner(),
          const SizedBox(height: 14),

          // 2. 4-COLUMN ROW KPI METRICS
          _buildTabletKpiMetricsRow(),
          const SizedBox(height: 16),

          // 3. MAIN DUAL-PANE (58% GRAFIK + 42% INSIGHT & EKSPOR)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT PANE: Grafik Visual & Tabel Rincian Data
              Expanded(
                flex: 58,
                child: Column(
                  children: [
                    _buildChartSection(),
                    const SizedBox(height: 14),
                    _buildDetailsTabSection(),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // RIGHT PANE: Algorithmic Insights & Kartu Ekspor
              Expanded(
                flex: 42,
                child: Column(
                  children: [
                    _buildAlgorithmicInsightsCard(),
                    const SizedBox(height: 14),
                    _buildTabletExportCard(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabletHeroBanner() {
    String scaleBadge;
    switch (widget.summary.scale) {
      case AnalyticsScale.yearly:
        scaleBadge = 'Skala 1 Tahun';
        break;
      case AnalyticsScale.monthly:
        scaleBadge = 'Skala 1 Bulan';
        break;
      case AnalyticsScale.customRange:
        scaleBadge = 'Skala Rentang';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.leadAsphalt, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        scaleBadge.toUpperCase(),
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.summary.dataPoints.length} TITIK DATA',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppTheme.slateGraphite,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.summary.periodTitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          // Quick Export Pills in Hero
          Row(
            children: [
              _buildQuickExportBtn(
                label: 'PDF',
                icon: Icons.picture_as_pdf_outlined,
                onTap: () async {
                  try {
                    final f = await SalesAnalyticsExportService.instance
                        .exportToPdf(widget.summary);
                    await Share.shareXFiles([XFile(f.path)], text: 'Analisis ${widget.summary.periodTitle}');
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal export: $e')));
                    }
                  }
                },
              ),
              const SizedBox(width: 6),
              _buildQuickExportBtn(
                label: 'EXCEL',
                icon: Icons.table_chart_outlined,
                onTap: () async {
                  try {
                    final f = await SalesAnalyticsExportService.instance
                        .exportToExcel(widget.summary);
                    await Share.shareXFiles([XFile(f.path)], text: 'Analisis Excel ${widget.summary.periodTitle}');
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal export: $e')));
                    }
                  }
                },
              ),
              const SizedBox(width: 6),
              _buildQuickExportBtn(
                label: 'PPTX',
                icon: Icons.slideshow_outlined,
                onTap: () async {
                  try {
                    final f = await SalesAnalyticsExportService.instance
                        .exportToPptx(widget.summary);
                    await Share.shareXFiles([XFile(f.path)], text: 'Slide Presentasi ${widget.summary.periodTitle}');
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal export: $e')));
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabletKpiMetricsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            code: 'REVENUE',
            title: 'Total Omset',
            value: CurrencyFormat.convertToIdr(widget.summary.totalRevenue, 0),
            icon: Icons.payments_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildKpiCard(
            code: 'COUNT',
            title: 'Total Transaksi',
            value: '${NumberFormat('#,###').format(widget.summary.totalTransactions)}x',
            icon: Icons.receipt_long_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildKpiCard(
            code: 'AVERAGE',
            title: 'Rata-rata Penjualan',
            value: CurrencyFormat.convertToIdr(widget.summary.averageRevenue, 0),
            icon: Icons.analytics_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildKpiCard(
            code: 'BASKET',
            title: 'Nilai Belanja (AOV)',
            value: CurrencyFormat.convertToIdr(_insights.averageOrderValue, 0),
            icon: Icons.shopping_basket_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildTabletExportCard() {
    return Container(
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
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceRecessed,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.cardBorderColor),
                ),
                child: const Icon(Icons.output_rounded, size: 14, color: AppTheme.textPrimary),
              ),
              const SizedBox(width: 8),
              Text(
                'Ekspor Laporan Analitik',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Format terstruktur dengan visual diagram batang & garis siap cetak/presentasikan.',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTabletExportAction(
                  format: 'PDF',
                  desc: 'Executive Brief',
                  icon: Icons.picture_as_pdf_outlined,
                  onTap: () async {
                    final f = await SalesAnalyticsExportService.instance.exportToPdf(widget.summary);
                    await Share.shareXFiles([XFile(f.path)], text: 'Analisis PDF ${widget.summary.periodTitle}');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTabletExportAction(
                  format: 'EXCEL',
                  desc: 'Buku Keuangan',
                  icon: Icons.table_chart_outlined,
                  onTap: () async {
                    final f = await SalesAnalyticsExportService.instance.exportToExcel(widget.summary);
                    await Share.shareXFiles([XFile(f.path)], text: 'Analisis Excel ${widget.summary.periodTitle}');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTabletExportAction(
                  format: 'PPTX',
                  desc: 'Slide Presentasi',
                  icon: Icons.slideshow_outlined,
                  onTap: () async {
                    final f = await SalesAnalyticsExportService.instance.exportToPptx(widget.summary);
                    await Share.shareXFiles([XFile(f.path)], text: 'Presentasi ${widget.summary.periodTitle}');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabletExportAction({
    required String format,
    required String desc,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceRecessed,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.cardBorderColor),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppTheme.textPrimary),
            const SizedBox(height: 5),
            Text(
              format,
              style: GoogleFonts.jetBrainsMono(
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 1. HERO PERIODE BANNER (MOBILE)
  // =========================================================================
  Widget _buildHeroBanner() {
    String scaleBadge;
    switch (widget.summary.scale) {
      case AnalyticsScale.yearly:
        scaleBadge = 'Skala 1 Tahun';
        break;
      case AnalyticsScale.monthly:
        scaleBadge = 'Skala 1 Bulan';
        break;
      case AnalyticsScale.customRange:
        scaleBadge = 'Skala Rentang';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.leadAsphalt, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Text(
                  scaleBadge.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                '${widget.summary.dataPoints.length} TITIK DATA',
                style: GoogleFonts.jetBrainsMono(
                  color: AppTheme.slateGraphite,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.summary.periodTitle,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Laporan analitik terintegrasi data transaksi kasir POS offline.',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.slateGraphite,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // BAR EKSPOR CEPAT (PDF, EXCEL, PPT)
  // =========================================================================
  Widget _buildQuickExportBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cardBorderColor),
      ),
      child: Row(
        children: [
          Text(
            'EKSPOR:',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          _buildQuickExportBtn(
            label: 'PDF',
            icon: Icons.picture_as_pdf_outlined,
            onTap: () async {
              try {
                final f = await SalesAnalyticsExportService.instance
                    .exportToPdf(widget.summary);
                await Share.shareXFiles([XFile(f.path)], text: 'Analisis ${widget.summary.periodTitle}');
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal export: $e')));
                }
              }
            },
          ),
          const SizedBox(width: 6),
          _buildQuickExportBtn(
            label: 'EXCEL',
            icon: Icons.table_chart_outlined,
            onTap: () async {
              try {
                final f = await SalesAnalyticsExportService.instance
                    .exportToExcel(widget.summary);
                await Share.shareXFiles([XFile(f.path)], text: 'Analisis ${widget.summary.periodTitle}');
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal export: $e')));
                }
              }
            },
          ),
          const SizedBox(width: 6),
          _buildQuickExportBtn(
            label: 'PPTX',
            icon: Icons.slideshow_outlined,
            onTap: () async {
              try {
                final f = await SalesAnalyticsExportService.instance
                    .exportToPptx(widget.summary);
                await Share.shareXFiles([XFile(f.path)], text: 'Analisis ${widget.summary.periodTitle}');
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal export: $e')));
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickExportBtn({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceRecessed,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppTheme.cardBorderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppTheme.textPrimary),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlgorithmicInsightsCard() {
    return Container(
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
                  Icons.insights_rounded,
                  color: AppTheme.textPrimary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rangkuman Intelijen Bisnis',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Analisis statistik tren dan stabilitas performa',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Badges Status Tren & Stabilitas
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildBadge(
                label: 'TREN: ${_insights.trendStatus.toUpperCase()}',
                dotColor: _insights.growthRatePercent >= 0
                    ? AppTheme.forestGreen
                    : AppTheme.stampRed,
              ),
              _buildBadge(
                label: 'STABILITAS: ${_insights.stabilityLevel.toUpperCase()}',
                dotColor: AppTheme.leadAsphalt,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Narasi Rangkuman Eksekutif
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceRecessed,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.cardBorderColor),
            ),
            child: Text(
              _insights.executiveSummary,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                height: 1.45,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Temuan Kunci (Key Findings)
          Text(
            'TEMUAN KUNCI DATA',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          ..._insights.keyFindings.map((finding) => _buildFindingTile(finding)),

          // Rekomendasi Taktis
          if (_insights.strategicRecommendations.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'REKOMENDASI TINDAKAN',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            ..._insights.strategicRecommendations.map(
              (rec) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3, right: 6),
                      child: Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: AppTheme.forestGreen,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        rec,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          height: 1.35,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required Color dotColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRecessed,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.cardBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFindingTile(InsightFinding finding) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppTheme.leadAsphalt,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  finding.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  finding.description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    height: 1.3,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 3. 4 KARTU KPI METRIK UTAMA
  // =========================================================================
  Widget _buildKpiMetricsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                code: 'REV',
                title: 'Total Omset',
                value: CurrencyFormat.convertToIdr(widget.summary.totalRevenue, 0),
                icon: Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpiCard(
                code: 'TRX',
                title: 'Total Transaksi',
                value: '${NumberFormat('#,###').format(widget.summary.totalTransactions)}x',
                icon: Icons.receipt_long_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                code: 'AVG',
                title: 'Rata-rata Penjualan',
                value: CurrencyFormat.convertToIdr(widget.summary.averageRevenue, 0),
                icon: Icons.analytics_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpiCard(
                code: 'AOV',
                title: 'Nilai Belanja (AOV)',
                value: CurrencyFormat.convertToIdr(_insights.averageOrderValue, 0),
                icon: Icons.shopping_basket_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String code,
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cardBorderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceRecessed,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: AppTheme.cardBorderColor),
                ),
                child: Text(
                  code,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8.5,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(icon, color: AppTheme.textMuted, size: 14),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.3,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 4. BAGIAN GRAFIK (DIAGRAM BATANG & GARIS DENGAN SWITCH BERSIH)
  // =========================================================================
  Widget _buildChartSection() {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Visualisasi Grafik Penjualan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Sentuh grafik untuk melihat nominal',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
              // Segmented Switcher Batang vs Garis
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceRecessed,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.cardBorderColor),
                ),
                child: Row(
                  children: [
                    _buildChartToggleBtn('bar', 'BATANG', Icons.bar_chart_rounded),
                    _buildChartToggleBtn('line', 'GARIS', Icons.show_chart_rounded),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppTheme.cardBorderColor),
          const SizedBox(height: 12),

          // Render chart widget
          SalesChartWidget(
            summary: widget.summary,
            chartType: _activeChartType,
          ),
        ],
      ),
    );
  }

  Widget _buildChartToggleBtn(String type, String label, IconData icon) {
    final isSelected = _activeChartType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _activeChartType = type;
        });
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryDark : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 5. DETAIL RINCIAN & PRODUK TERLARIS (TABBED)
  // =========================================================================
  Widget _buildDetailsTabSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cardBorderColor),
      ),
      child: Column(
        children: [
          // Tab Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                _buildSubTabHeader(0, 'RINCIAN PENJUALAN', Icons.table_chart_outlined),
                const SizedBox(width: 6),
                _buildSubTabHeader(1, 'TOP PRODUK', Icons.leaderboard_outlined),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.cardBorderColor),

          // Tab Content
          if (_bottomTab == 0)
            _buildBreakdownContent()
          else
            _buildTopProductsContent(),
        ],
      ),
    );
  }

  Widget _buildSubTabHeader(int index, String label, IconData icon) {
    final isSelected = _bottomTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _bottomTab = index;
        });
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryDark : AppTheme.surfaceRecessed,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? AppTheme.primaryDark : AppTheme.cardBorderColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownContent() {
    final points = widget.summary.dataPoints;
    if (points.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Tidak ada data rincian.',
          style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12),
        ),
      );
    }

    return Column(
      children: [
        // Column Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: AppTheme.surfaceRecessed,
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'PERIODE',
                  style: GoogleFonts.jetBrainsMono(
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'TRANSAKSI',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jetBrainsMono(
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  'TOTAL OMSET',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.jetBrainsMono(
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.cardBorderColor),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: points.length,
          separatorBuilder: (context, index) =>
              const Divider(height: 1, color: AppTheme.cardBorderColor),
          itemBuilder: (context, idx) {
            final p = points[idx];
            final isHighest = widget.summary.highestPoint != null &&
                widget.summary.highestPoint!.dateKey == p.dateKey &&
                p.totalAmount > 0;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: isHighest ? AppTheme.rawBrass.withValues(alpha: 0.08) : Colors.transparent,
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Row(
                      children: [
                        if (isHighest)
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: AppTheme.rawBrass,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            p.fullLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: isHighest ? FontWeight.w800 : FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${p.transactionCount}x',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        color: p.transactionCount > 0
                            ? AppTheme.textPrimary
                            : AppTheme.textMuted,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      CurrencyFormat.convertToIdr(p.totalAmount, 0),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: p.totalAmount > 0
                            ? (isHighest ? AppTheme.rawBrass : AppTheme.textPrimary)
                            : AppTheme.textMuted,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTopProductsContent() {
    final items = widget.summary.topProducts;
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Belum ada data barang terjual pada periode ini.',
          style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        children: items.take(7).map((item) {
          final idx = items.indexOf(item) + 1;
          final name = item['product_name'] ?? '-';
          final qty = item['total_qty'] ?? 0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: idx == 1
                        ? AppTheme.primaryDark
                        : AppTheme.surfaceRecessed,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: idx == 1 ? AppTheme.primaryDark : AppTheme.cardBorderColor,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$idx',
                      style: GoogleFonts.jetBrainsMono(
                        color: idx == 1 ? Colors.white : AppTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceRecessed,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.cardBorderColor),
                  ),
                  child: Text(
                    '$qty pcs',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
