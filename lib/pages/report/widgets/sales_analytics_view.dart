import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../controllers/sales_analytics_controller.dart';
import '../../../controllers/tablet_mode_controller.dart';
import '../../../models/sales_analytics_model.dart';
import '../../../services/sales_analytics_export_service.dart';
import '../../../config/app_theme.dart';
import '../sales_analytics_dashboard_page.dart';

class SalesAnalyticsView extends StatefulWidget {
  const SalesAnalyticsView({super.key});

  @override
  State<SalesAnalyticsView> createState() => _SalesAnalyticsViewState();
}

class _SalesAnalyticsViewState extends State<SalesAnalyticsView> {
  final SalesAnalyticsController _controller = SalesAnalyticsController();

  static const List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onStateChange);
    _controller.init();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChange);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleStartAnalysis() async {
    await _controller.analyze();

    if (!mounted) return;

    if (_controller.summary != null) {
      _showPostAnalysisChoiceModal(_controller.summary!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data penjualan.', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: AppTheme.stampRed,
        ),
      );
    }
  }

  void _showPostAnalysisChoiceModal(SalesAnalyticsSummary summary) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          border: Border(
            top: BorderSide(color: AppTheme.cardBorderColor, width: 1),
            left: BorderSide(color: AppTheme.cardBorderColor, width: 1),
            right: BorderSide(color: AppTheme.cardBorderColor, width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.cardBorderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppTheme.forestGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.forestGreen.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
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
                        'ANALISIS SELESAI',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Pilih tindakan untuk periode: ${summary.periodTitle}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppTheme.cardBorderColor),
            const SizedBox(height: 12),

            // Opsi 1: Buka Dashboard Visual di Aplikasi
            _buildActionCard(
              formatCode: 'GUI',
              title: 'Buka Dashboard Interaktif',
              subtitle: 'Lihat diagram batang, grafik garis & metrik langsung',
              icon: Icons.dashboard_outlined,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SalesAnalyticsDashboardPage(summary: summary),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            // Opsi 2: Ekspor PDF
            _buildActionCard(
              formatCode: 'PDF',
              title: 'Ekspor Dokumen PDF (.pdf)',
              subtitle: 'Laporan resmi terstruktur siap cetak atau dibagikan',
              icon: Icons.picture_as_pdf_outlined,
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final f = await SalesAnalyticsExportService.instance.exportToPdf(summary);
                  await Share.shareXFiles([XFile(f.path)], text: 'Analisis Penjualan ${summary.periodTitle}');
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal export: $e')));
                  }
                }
              },
            ),
            const SizedBox(height: 8),

            // Opsi 3: Ekspor Excel
            _buildActionCard(
              formatCode: 'XLSX',
              title: 'Ekspor Spreadsheet Excel (.xlsx)',
              subtitle: 'Buku laporan angka terstruktur rapi untuk akuntansi',
              icon: Icons.table_chart_outlined,
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final f = await SalesAnalyticsExportService.instance.exportToExcel(summary);
                  await Share.shareXFiles([XFile(f.path)], text: 'Analisis Penjualan ${summary.periodTitle}');
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal export: $e')));
                  }
                }
              },
            ),
            const SizedBox(height: 8),

            // Opsi 4: Ekspor PowerPoint
            _buildActionCard(
              formatCode: 'PPTX',
              title: 'Ekspor Presentasi PowerPoint (.pptx)',
              subtitle: 'Slide 16:9 widescreen eksekutif siap presentasi',
              icon: Icons.slideshow_outlined,
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final f = await SalesAnalyticsExportService.instance.exportToPptx(summary);
                  await Share.shareXFiles([XFile(f.path)], text: 'Analisis Penjualan ${summary.periodTitle}');
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
    );
  }

  Widget _buildActionCard({
    required String formatCode,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceRecessed,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.cardBorderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.cardBorderColor),
              ),
              child: Text(
                formatCode,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  String _getPreviewDescription() {
    switch (_controller.scale) {
      case AnalyticsScale.yearly:
        return 'Sistem akan mengumpulkan dan menganalisis seluruh data transaksi penjualan selama 12 bulan di Tahun ${_controller.selectedYear}.';
      case AnalyticsScale.monthly:
        return 'Sistem akan mengumpulkan data harian (tanggal 1 s/d akhir bulan) untuk ${_monthNames[_controller.selectedMonth - 1]} ${_controller.selectedYear}.';
      case AnalyticsScale.customRange:
        return 'Sistem akan menganalisis tren omset per bulan dari ${_monthNames[_controller.startMonth - 1]} s/d ${_monthNames[_controller.endMonth - 1]} ${_controller.selectedYear}.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = context.watch<TabletModeController>().isTabletLayout(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER KARTU UTAMA
          Container(
            padding: const EdgeInsets.all(18),
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceRecessed,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.cardBorderColor),
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        color: AppTheme.textPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Analisis Data Penjualan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Pilih skala periode untuk membuka dashboard analitik',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppTheme.cardBorderColor),
                const SizedBox(height: 16),

                if (isTablet) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kolom Kiri: Pilihan Skala
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '// 01 SKALA PERIODE ANALISIS',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildScaleTile(
                              code: '1Y',
                              scale: AnalyticsScale.yearly,
                              title: '1 Tahun Penuh (12 Bulan)',
                              subtitle: 'Menganalisis performa bulanan selama satu tahun kalender',
                              icon: Icons.calendar_today_rounded,
                            ),
                            const SizedBox(height: 8),
                            _buildScaleTile(
                              code: '1M',
                              scale: AnalyticsScale.monthly,
                              title: '1 Bulan Penuh (Harian)',
                              subtitle: 'Menganalisis tren penjualan harian pada bulan tertentu',
                              icon: Icons.calendar_view_month_rounded,
                            ),
                            const SizedBox(height: 8),
                            _buildScaleTile(
                              code: 'RNG',
                              scale: AnalyticsScale.customRange,
                              title: 'Periode Tertentu (Rentang Bulan)',
                              subtitle: 'Menganalisis rentang bulan khusus pada tahun tertentu',
                              icon: Icons.date_range_rounded,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),

                      // Kolom Kanan: Parameter, Preview, & Aksi
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '// 02 WAKTU PERIODE',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildTimeParameters(),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceRecessed,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.cardBorderColor),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    size: 16,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _getPreviewDescription(),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        height: 1.4,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton(
                                onPressed: _controller.isLoading ? null : _handleStartAnalysis,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryDark,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  elevation: 0,
                                ),
                                child: _controller.isLoading
                                    ? const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Text('MENGANALISIS DATA...'),
                                        ],
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'BUKA DASHBOARD ANALISIS',
                                            style: GoogleFonts.jetBrainsMono(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.arrow_forward_rounded, size: 16),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // 1. PILIHAN SKALA PERIODE
                  Text(
                    '// 01 SKALA PERIODE ANALISIS',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildScaleTile(
                    code: '1Y',
                    scale: AnalyticsScale.yearly,
                    title: '1 Tahun Penuh (12 Bulan)',
                    subtitle: 'Menganalisis performa bulanan selama satu tahun kalender',
                    icon: Icons.calendar_today_rounded,
                  ),
                  const SizedBox(height: 8),
                  _buildScaleTile(
                    code: '1M',
                    scale: AnalyticsScale.monthly,
                    title: '1 Bulan Penuh (Harian)',
                    subtitle: 'Menganalisis tren penjualan harian pada bulan tertentu',
                    icon: Icons.calendar_view_month_rounded,
                  ),
                  const SizedBox(height: 8),
                  _buildScaleTile(
                    code: 'RNG',
                    scale: AnalyticsScale.customRange,
                    title: 'Periode Tertentu (Rentang Bulan)',
                    subtitle: 'Menganalisis rentang bulan khusus pada tahun tertentu',
                    icon: Icons.date_range_rounded,
                  ),
                  const SizedBox(height: 18),

                  // 2. FORM PARAMETER WAKTU
                  Text(
                    '// 02 WAKTU PERIODE',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTimeParameters(),
                  const SizedBox(height: 14),

                  // 3. KARTU PREVIEW INFORMASI
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceRecessed,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.cardBorderColor),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getPreviewDescription(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              height: 1.4,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 4. TOMBOL EKSEKUSI BESAR
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _controller.isLoading ? null : _handleStartAnalysis,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                      ),
                      child: _controller.isLoading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text('MENGANALISIS DATA...'),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'BUKA DASHBOARD ANALISIS',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 16),
                              ],
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScaleTile({
    required String code,
    required AnalyticsScale scale,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _controller.scale == scale;
    return InkWell(
      onTap: () => _controller.setScale(scale),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : AppTheme.surfaceRecessed,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppTheme.primaryDark : AppTheme.cardBorderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryDark : Colors.white,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryDark : AppTheme.cardBorderColor,
                ),
              ),
              child: Text(
                code,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppTheme.primaryDark : AppTheme.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeParameters() {
    switch (_controller.scale) {
      case AnalyticsScale.yearly:
        return _buildDropdownContainer(
          label: 'TAHUN PENJUALAN',
          child: DropdownButton<int>(
            isExpanded: true,
            value: _controller.selectedYear,
            icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
            items: _controller.availableYears.map((yr) {
              return DropdownMenuItem<int>(
                value: yr,
                child: Text(
                  'Tahun $yr',
                  style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              );
            }).toList(),
            onChanged: (yr) {
              if (yr != null) _controller.setSelectedYear(yr);
            },
          ),
        );

      case AnalyticsScale.monthly:
        return Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildDropdownContainer(
                label: 'BULAN',
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: _controller.selectedMonth,
                  icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                  items: List.generate(12, (i) {
                    final m = i + 1;
                    return DropdownMenuItem<int>(
                      value: m,
                      child: Text(
                        _monthNames[i],
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    );
                  }),
                  onChanged: (m) {
                    if (m != null) _controller.setSelectedMonth(m);
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _buildDropdownContainer(
                label: 'TAHUN',
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: _controller.selectedYear,
                  icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                  items: _controller.availableYears.map((yr) {
                    return DropdownMenuItem<int>(
                      value: yr,
                      child: Text(
                        '$yr',
                        style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (yr) {
                    if (yr != null) _controller.setSelectedYear(yr);
                  },
                ),
              ),
            ),
          ],
        );

      case AnalyticsScale.customRange:
        return Column(
          children: [
            _buildDropdownContainer(
              label: 'TAHUN',
              child: DropdownButton<int>(
                isExpanded: true,
                value: _controller.selectedYear,
                icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                items: _controller.availableYears.map((yr) {
                  return DropdownMenuItem<int>(
                    value: yr,
                    child: Text(
                      'Tahun $yr',
                      style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (yr) {
                  if (yr != null) _controller.setSelectedYear(yr);
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildDropdownContainer(
                    label: 'DARI BULAN',
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _controller.startMonth,
                      icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                      items: List.generate(12, (i) {
                        final m = i + 1;
                        return DropdownMenuItem<int>(
                          value: m,
                          child: Text(
                            _monthNames[i],
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 12.5),
                          ),
                        );
                      }),
                      onChanged: (m) {
                        if (m != null) {
                          _controller.setMonthRange(m, _controller.endMonth);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDropdownContainer(
                    label: 'SAMPAI BULAN',
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _controller.endMonth,
                      icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                      items: List.generate(12, (i) {
                        final m = i + 1;
                        return DropdownMenuItem<int>(
                          value: m,
                          child: Text(
                            _monthNames[i],
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 12.5),
                          ),
                        );
                      }),
                      onChanged: (m) {
                        if (m != null) {
                          _controller.setMonthRange(_controller.startMonth, m);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  Widget _buildDropdownContainer({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceRecessed,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.cardBorderColor),
          ),
          child: DropdownButtonHideUnderline(child: child),
        ),
      ],
    );
  }
}
