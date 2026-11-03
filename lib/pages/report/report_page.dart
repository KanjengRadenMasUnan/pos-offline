import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/report_controller.dart';
import '../../controllers/tablet_mode_controller.dart';
import '../../config/app_theme.dart';
import 'widgets/sales_analytics_view.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final ReportController _controller = ReportController();
  String _mode = 'Bulanan';

  DateTime _selectedDate = DateTime.now();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    if (_mode == 'Harian') {
      await _controller.loadDailyReport(_selectedDate);
    } else {
      await _controller.loadMonthlyReport(_selectedMonth, _selectedYear);
    }
    if (mounted) setState(() {});
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _loadReport();
    }
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_selectedYear, _selectedMonth),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = picked.month;
        _selectedYear = picked.year;
      });
      _loadReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(49),
            child: Column(
              children: [
                Container(
                  height: 38,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceRecessed,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.cardBorderColor),
                  ),
                  child: TabBar(
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppTheme.primaryDark,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.textSecondary,
                    labelStyle: GoogleFonts.jetBrainsMono(
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                      letterSpacing: 0.3,
                    ),
                    unselectedLabelStyle: GoogleFonts.jetBrainsMono(
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                    ),
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_rounded, size: 14),
                            SizedBox(width: 6),
                            Text('REKAP TRANSAKSI'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_graph_rounded, size: 14),
                            SizedBox(width: 6),
                            Text('ANALISIS & GRAFIK'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(color: AppTheme.cardBorderColor, height: 1),
              ],
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            children: [
              Text(
                'Laporan & Analitik',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppTheme.textPrimary,
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
                  'FINANCIAL-LOG',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _controller.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryDark,
                      strokeWidth: 2,
                    ),
                  )
                : _buildRekapTab(),
            const SalesAnalyticsView(),
          ],
        ),
      ),
    );
  }

  Widget _buildRekapTab() {
    final isTablet = context.watch<TabletModeController>().isTabletLayout(context);

    final leftControls = Column(
      children: [
        // Segmented Switch Mode (Harian / Bulanan)
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppTheme.surfaceRecessed,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.cardBorderColor),
          ),
          child: Row(
            children: [
              _buildModeBtn(
                'Bulanan',
                'REKAP BULANAN',
                Icons.calendar_month_rounded,
              ),
              _buildModeBtn(
                'Harian',
                'REKAP HARIAN',
                Icons.calendar_today_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Pemilih Tanggal / Bulan
        InkWell(
          onTap: _mode == 'Harian' ? _pickDate : _pickMonth,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.cardBorderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceRecessed,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.cardBorderColor),
                  ),
                  child: Icon(
                    _mode == 'Harian'
                        ? Icons.calendar_today_rounded
                        : Icons.calendar_month_rounded,
                    color: AppTheme.textPrimary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _mode == 'Harian'
                            ? 'PERIODE HARIAN'
                            : 'PERIODE BULAN & TAHUN',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.5,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _mode == 'Harian'
                            ? DateFormat(
                                'EEEE, dd MMMM yyyy',
                                'id_ID',
                              ).format(_selectedDate)
                            : DateFormat('MMMM yyyy', 'id_ID').format(
                                DateTime(_selectedYear, _selectedMonth),
                              ),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "UBAH →",
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Total Pendapatan Monolith Card
        _buildIncomeCard(),
      ],
    );

    final rightList = Column(
      children: [
        // Produk Paling Laris
        _buildSection(
          code: "TOP-SALES",
          title: 'Produk Paling Laris',
          icon: Icons.trending_up_rounded,
          items: _controller.topSelling,
          emptyText: 'Belum ada data penjualan pada periode ini.',
          itemBuilder: (item) => Row(
            children: [
              Expanded(
                child: Text(
                  item['product_name'] ?? '-',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceRecessed,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.cardBorderColor),
                ),
                child: Text(
                  '${item['total_qty']}x TERJUAL',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Rincian Barang Terjual
        _buildSection(
          code: "SALES-DETAIL",
          title: 'Rincian Barang Terjual',
          icon: Icons.shopping_bag_outlined,
          items: _controller.soldItems,
          emptyText: 'Tidak ada transaksi pada periode ini.',
          itemBuilder: (item) => Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['product_name'] ?? '-',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${item['total_qty']} unit',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Rp ${NumberFormat('#,###').format(item['total_sales'])}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Peringatan Stok Menipis
        _buildSection(
          code: "LOW-STOCK",
          title: 'Peringatan Stok Menipis (≤ 5)',
          icon: Icons.warning_amber_rounded,
          items: _controller.lowStock,
          emptyText: 'Semua persediaan stok aman.',
          itemBuilder: (item) => Row(
            children: [
              Expanded(
                child: Text(
                  item['name'] ?? '-',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.rawBrass.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.rawBrass.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'SISA ${item['stock']}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.rawBrass,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Stok Habis
        _buildSection(
          code: "ZERO-STOCK",
          title: 'Persediaan Stok Habis (0)',
          icon: Icons.remove_shopping_cart_outlined,
          items: _controller.outOfStock,
          emptyText: 'Tidak ada barang dengan stok habis.',
          itemBuilder: (item) => Row(
            children: [
              Expanded(
                child: Text(
                  item['name'] ?? '-',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.stampRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.stampRed.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'HABIS',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.stampRed,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );

    if (isTablet) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        physics: const BouncingScrollPhysics(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 4, child: leftControls),
            const SizedBox(width: 16),
            Expanded(flex: 6, child: rightList),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          leftControls,
          const SizedBox(height: 14),
          rightList,
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildModeBtn(String val, String label, IconData icon) {
    final isSelected = _mode == val;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (_mode != val) {
            setState(() {
              _mode = val;
            });
            _loadReport();
          }
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryDark : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeCard() {
    final formatted = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(_controller.totalIncome);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.leadAsphalt, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
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
                    'TOTAL PENDAPATAN',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppTheme.slateGraphite,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                formatted,
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String code,
    required String title,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required String emptyText,
    required Widget Function(Map<String, dynamic>) itemBuilder,
  }) {
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
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceRecessed,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.cardBorderColor),
                ),
                child: Text(
                  code,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppTheme.cardBorderColor),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                emptyText,
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 12, color: AppTheme.cardBorderColor),
              itemBuilder: (context, index) => itemBuilder(items[index]),
            ),
        ],
      ),
    );
  }
}
