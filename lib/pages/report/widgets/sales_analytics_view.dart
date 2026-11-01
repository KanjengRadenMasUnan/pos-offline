import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../controllers/sales_analytics_controller.dart';
import '../../../models/sales_analytics_model.dart';
import '../../../services/sales_analytics_export_service.dart';
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
        const SnackBar(
          content: Text('Gagal memuat data penjualan.'),
          backgroundColor: Colors.red,
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
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF059669),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Analisis Selesai! Pilih Tindakan:',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        summary.periodTitle,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Opsi 1: Buka Dashboard Visual di Aplikasi
            _buildActionCard(
              title: 'Buka Dashboard Interaktif',
              subtitle: 'Lihat grafik visual batang/garis dan metrik langsung di aplikasi',
              icon: Icons.dashboard_customize_rounded,
              color: const Color(0xFF2563EB),
              bgColor: const Color(0xFFEFF6FF),
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
            const SizedBox(height: 12),

            // Opsi 2: Ekspor PDF
            _buildActionCard(
              title: 'Ekspor ke Dokumen PDF (.pdf)',
              subtitle: 'Laporan resmi siap cetak atau dibagikan',
              icon: Icons.picture_as_pdf_rounded,
              color: const Color(0xFFDC2626),
              bgColor: const Color(0xFFFEF2F2),
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
            const SizedBox(height: 12),

            // Opsi 3: Ekspor Excel
            _buildActionCard(
              title: 'Ekspor ke Spreadsheet Excel (.xlsx)',
              subtitle: 'File data angka lengkap terstruktur',
              icon: Icons.table_chart_rounded,
              color: const Color(0xFF059669),
              bgColor: const Color(0xFFECFDF5),
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
            const SizedBox(height: 12),

            // Opsi 4: Ekspor PowerPoint
            _buildActionCard(
              title: 'Ekspor ke Presentasi PowerPoint (.pptx)',
              subtitle: 'Slide 16:9 widescreen eksekutif siap presentasi',
              icon: Icons.slideshow_rounded,
              color: const Color(0xFFEA580C),
              bgColor: const Color(0xFFFFF7ED),
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
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: Color(0xFF94A3B8),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER KARTU UTAMA
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.analytics_rounded,
                        color: Color(0xFF2563EB),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Analisis Data Penjualan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Pilih periode analitik untuk membuka dashboard',
                            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // 1. PILIHAN SKALA PERIODE (3 PILIHAN BERSIH)
                const Text(
                  '1. Pilih Skala Periode Analisis',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 12),
                _buildScaleTile(
                  scale: AnalyticsScale.yearly,
                  title: '1 Tahun Penuh (12 Bulan)',
                  subtitle: 'Menganalisis performa bulanan selama satu tahun kalender',
                  icon: Icons.calendar_today_rounded,
                ),
                const SizedBox(height: 10),
                _buildScaleTile(
                  scale: AnalyticsScale.monthly,
                  title: '1 Bulan Penuh (Harian)',
                  subtitle: 'Menganalisis tren penjualan harian pada bulan tertentu',
                  icon: Icons.calendar_view_month_rounded,
                ),
                const SizedBox(height: 10),
                _buildScaleTile(
                  scale: AnalyticsScale.customRange,
                  title: 'Periode Tertentu (Rentang Bulan)',
                  subtitle: 'Menganalisis rentang bulan khusus pada tahun tertentu',
                  icon: Icons.date_range_rounded,
                ),
                const SizedBox(height: 22),

                // 2. FORM PARAMETER WAKTU
                const Text(
                  '2. Tentukan Waktu Periode',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTimeParameters(),
                const SizedBox(height: 20),

                // 3. KARTU PREVIEW INFORMASI
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _getPreviewDescription(),
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.45,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 4. TOMBOL EKSEKUSI BESAR
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _controller.isLoading ? null : _handleStartAnalysis,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _controller.isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Menganalisis Seluruh Data...',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.dashboard_customize_rounded, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Buka Dashboard Analisis',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScaleTile({
    required AnalyticsScale scale,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _controller.scale == scale;
    return InkWell(
      onTap: () => _controller.setScale(scale),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
              size: 20,
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
          label: 'Tahun Penjualan',
          child: DropdownButton<int>(
            isExpanded: true,
            value: _controller.selectedYear,
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2563EB)),
            items: _controller.availableYears.map((yr) {
              return DropdownMenuItem<int>(
                value: yr,
                child: Text(
                  'Tahun $yr',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
                label: 'Bulan',
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: _controller.selectedMonth,
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2563EB)),
                  items: List.generate(12, (i) {
                    final m = i + 1;
                    return DropdownMenuItem<int>(
                      value: m,
                      child: Text(
                        _monthNames[i],
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    );
                  }),
                  onChanged: (m) {
                    if (m != null) _controller.setSelectedMonth(m);
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _buildDropdownContainer(
                label: 'Tahun',
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: _controller.selectedYear,
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2563EB)),
                  items: _controller.availableYears.map((yr) {
                    return DropdownMenuItem<int>(
                      value: yr,
                      child: Text(
                        '$yr',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
              label: 'Tahun',
              child: DropdownButton<int>(
                isExpanded: true,
                value: _controller.selectedYear,
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2563EB)),
                items: _controller.availableYears.map((yr) {
                  return DropdownMenuItem<int>(
                    value: yr,
                    child: Text(
                      'Tahun $yr',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (yr) {
                  if (yr != null) _controller.setSelectedYear(yr);
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDropdownContainer(
                    label: 'Dari Bulan',
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _controller.startMonth,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2563EB)),
                      items: List.generate(12, (i) {
                        final m = i + 1;
                        return DropdownMenuItem<int>(
                          value: m,
                          child: Text(
                            _monthNames[i],
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdownContainer(
                    label: 'Sampai Bulan',
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _controller.endMonth,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2563EB)),
                      items: List.generate(12, (i) {
                        final m = i + 1;
                        return DropdownMenuItem<int>(
                          value: m,
                          child: Text(
                            _monthNames[i],
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(child: child),
        ),
      ],
    );
  }
}
