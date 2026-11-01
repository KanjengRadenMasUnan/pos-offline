import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/sales_analytics_model.dart';
import '../../services/sales_insight_engine.dart';
import '../../services/sales_analytics_export_service.dart';
import '../../utils/currency_format.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Dashboard Analitik Penjualan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_rounded),
            tooltip: 'Ekspor Hasil Analisis (PDF / Excel / PPT)',
            onPressed: () =>
                SalesAnalyticsExportService.showExportModal(context, widget.summary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. HERO PERIODE BANNER
            _buildHeroBanner(),
            const SizedBox(height: 14),

            // BAR EKSPOR CEPAT (PDF, EXCEL, PPT)
            _buildQuickExportBar(),
            const SizedBox(height: 18),

            // 2. KARTU INSIGHT BERBASIS ALGORITMA CERDAS
            _buildAlgorithmicInsightsCard(),
            const SizedBox(height: 18),

            // 3. 4 KARTU KPI METRIK UTAMA
            _buildKpiMetricsGrid(),
            const SizedBox(height: 22),

            // 4. BAGIAN GRAFIK (DIAGRAM BATANG & GARIS)
            _buildChartSection(),
            const SizedBox(height: 22),

            // 5. DETAIL RINCIAN & PRODUK TERLARIS (TABBED)
            _buildDetailsTabSection(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 1. HERO PERIODE BANNER
  // =========================================================================
  Widget _buildHeroBanner() {
    String scaleBadge;
    switch (widget.summary.scale) {
      case AnalyticsScale.yearly:
        scaleBadge = 'Skala 1 Tahun Penuh';
        break;
      case AnalyticsScale.monthly:
        scaleBadge = 'Skala 1 Bulan Penuh';
        break;
      case AnalyticsScale.customRange:
        scaleBadge = 'Skala Rentang Periode';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.query_stats_rounded,
                      size: 14,
                      color: Color(0xFF38BDF8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      scaleBadge,
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${widget.summary.dataPoints.length} Titik Waktu',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.summary.periodTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Laporan analitik terintegrasi data penjualan offline & transaksi kasir.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.file_download_outlined, size: 20, color: Color(0xFF475569)),
          const SizedBox(width: 8),
          const Text(
            'Ekspor:',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildQuickExportBtn(
                  label: 'PDF',
                  icon: Icons.picture_as_pdf_rounded,
                  color: const Color(0xFFDC2626),
                  bgColor: const Color(0xFFFEF2F2),
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
                  label: 'Excel',
                  icon: Icons.table_chart_rounded,
                  color: const Color(0xFF059669),
                  bgColor: const Color(0xFFECFDF5),
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
                  label: 'PPT',
                  icon: Icons.slideshow_rounded,
                  color: const Color(0xFFEA580C),
                  bgColor: const Color(0xFFFFF7ED),
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
          ),
        ],
      ),
    );
  }

  Widget _buildQuickExportBtn({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildAlgorithmicInsightsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Insight
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: Color(0xFF4F46E5),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rangkuman & Intelijen Bisnis',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Kalkulasi statistik dan evaluasi performa tren penjualan',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Badges Status Tren & Stabilitas
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBadge(
                label: 'Tren: ${_insights.trendStatus}',
                icon: _insights.growthRatePercent >= 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: _insights.growthRatePercent >= 0
                    ? const Color(0xFF059669)
                    : const Color(0xFFDC2626),
                bgColor: _insights.growthRatePercent >= 0
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFFEF2F2),
              ),
              _buildBadge(
                label: 'Stabilitas: ${_insights.stabilityLevel}',
                icon: Icons.speed_rounded,
                color: const Color(0xFF7C3AED),
                bgColor: const Color(0xFFF5F3FF),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Narasi Rangkuman Eksekutif
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              _insights.executiveSummary,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.55,
                color: Color(0xFF334155),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Temuan Kunci (Key Findings)
          const Text(
            'Temuan Kunci Data',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          ..._insights.keyFindings.map((finding) => _buildFindingTile(finding)),
          const SizedBox(height: 16),

          // Rekomendasi Taktis
          if (_insights.strategicRecommendations.isNotEmpty) ...[
            const Text(
              'Rekomendasi Tindakan Strategis',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            ..._insights.strategicRecommendations.map(
              (rec) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4, right: 8),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        rec,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Color(0xFF334155),
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
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFindingTile(InsightFinding finding) {
    Color iconColor;
    Color iconBg;
    IconData icon;

    switch (finding.type) {
      case 'positive':
        iconColor = const Color(0xFF059669);
        iconBg = const Color(0xFFECFDF5);
        icon = Icons.trending_up_rounded;
        break;
      case 'warning':
        iconColor = const Color(0xFFD97706);
        iconBg = const Color(0xFFFFFBEB);
        icon = Icons.warning_amber_rounded;
        break;
      case 'highlight':
        iconColor = const Color(0xFF2563EB);
        iconBg = const Color(0xFFEFF6FF);
        icon = Icons.star_rounded;
        break;
      default:
        iconColor = const Color(0xFF64748B);
        iconBg = const Color(0xFFF1F5F9);
        icon = Icons.info_outline_rounded;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  finding.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  finding.description,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: Color(0xFF64748B),
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
                title: 'Total Omset',
                value: CurrencyFormat.convertToIdr(widget.summary.totalRevenue, 0),
                icon: Icons.payments_rounded,
                color: const Color(0xFF059669),
                bgColor: const Color(0xFFECFDF5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                title: 'Total Transaksi',
                value: '${NumberFormat('#,###').format(widget.summary.totalTransactions)}x',
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: 'Rata-rata Penjualan',
                value: CurrencyFormat.convertToIdr(widget.summary.averageRevenue, 0),
                icon: Icons.functions_rounded,
                color: const Color(0xFF7C3AED),
                bgColor: const Color(0xFFF5F3FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                title: 'Nilai Belanja (AOV)',
                value: CurrencyFormat.convertToIdr(_insights.averageOrderValue, 0),
                icon: Icons.shopping_basket_rounded,
                color: const Color(0xFFD97706),
                bgColor: const Color(0xFFFFFBEB),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Visualisasi Grafik Penjualan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Sentuh grafik untuk melihat detail nominal',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              // Segmented Switcher Batang vs Garis
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildChartToggleBtn('bar', 'Batang', Icons.bar_chart_rounded),
                    _buildChartToggleBtn('line', 'Garis', Icons.show_chart_rounded),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),

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
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFF1E88E5) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF1E88E5) : const Color(0xFF64748B),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tab Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                _buildSubTabHeader(0, 'Rincian Angka Penjualan', Icons.table_chart_rounded),
                const SizedBox(width: 10),
                _buildSubTabHeader(1, 'Top Produk Terlaris', Icons.local_fire_department_rounded),
              ],
            ),
          ),
          const Divider(height: 1),

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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF93C5FD) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
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
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Tidak ada data rincian.', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: [
        // Column Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFFF8FAFC),
          child: const Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'Periode',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Transaksi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  'Total Omset',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: points.length,
          separatorBuilder: (context, index) =>
              Divider(height: 1, color: Colors.grey.shade100),
          itemBuilder: (context, idx) {
            final p = points[idx];
            final isHighest = widget.summary.highestPoint != null &&
                widget.summary.highestPoint!.dateKey == p.dateKey &&
                p.totalAmount > 0;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              color: isHighest ? const Color(0xFFFFFBEB) : Colors.transparent,
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
                              size: 16,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            p.fullLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isHighest ? FontWeight.bold : FontWeight.w500,
                              color: const Color(0xFF334155),
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
                      style: TextStyle(
                        fontSize: 13,
                        color: p.transactionCount > 0
                            ? const Color(0xFF0F172A)
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      CurrencyFormat.convertToIdr(p.totalAmount, 0),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: p.totalAmount > 0
                            ? (isHighest ? const Color(0xFFB45309) : const Color(0xFF0F172A))
                            : Colors.grey.shade400,
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
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Belum ada data barang terjual pada periode ini.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: items.take(7).map((item) {
          final idx = items.indexOf(item) + 1;
          final name = item['product_name'] ?? '-';
          final qty = item['total_qty'] ?? 0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: idx == 1
                        ? const Color(0xFFFEF3C7)
                        : (idx == 2 ? const Color(0xFFF1F5F9) : const Color(0xFFFFF7ED)),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$idx',
                      style: TextStyle(
                        color: idx == 1
                            ? const Color(0xFFB45309)
                            : (idx == 2 ? const Color(0xFF475569) : const Color(0xFFC2410C)),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$qty pcs',
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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

