import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/report_controller.dart';
import '../../services/report_pdf_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

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
      _selectedDate = picked;
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

  Future<void> _exportPdf() async {
    // Siapkan data
    final reportTitle = _mode == 'Harian'
        ? 'Laporan Harian'
        : 'Laporan Bulanan';
    final period = _mode == 'Harian'
        ? DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate)
        : DateFormat(
            'MMMM yyyy',
            'id_ID',
          ).format(DateTime(_selectedYear, _selectedMonth));

    try {
      final pdfService = ReportPdfService();
      final file = await pdfService.generateReportPdf(
        reportTitle: reportTitle,
        period: period,
        totalIncome: _controller.totalIncome,
        topSelling: _controller.topSelling,
        soldItems: _controller.soldItems,
        lowStock: _controller.lowStock,
        outOfStock: _controller.outOfStock,
      );

      // Bagikan atau cetak
      await Share.shareXFiles([XFile(file.path)], text: 'Laporan $period');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal export PDF: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: _controller.isLoading ? null : _exportPdf,
          ),
        ],
      ),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Toggle Harian / Bulanan
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'Harian',
                        label: Text(
                          'Harian',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      ButtonSegment(
                        value: 'Bulanan',
                        label: Text(
                          'Bulanan',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (sel) {
                      setState(() {
                        _mode = sel.first;
                      });
                      _loadReport();
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.blue.shade50;
                        }
                        return Colors.grey.shade100;
                      }),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Pemilih Tanggal / Bulan
                  if (_mode == 'Harian')
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.calendar_today,
                          color: Colors.blue,
                        ),
                        title: Text(
                          DateFormat(
                            'EEEE, dd MMMM yyyy',
                            'id_ID',
                          ).format(_selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: const Icon(Icons.edit),
                        onTap: _pickDate,
                      ),
                    )
                  else
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.calendar_month,
                          color: Colors.blue,
                        ),
                        title: Text(
                          DateFormat(
                            'MMMM yyyy',
                            'id_ID',
                          ).format(DateTime(_selectedYear, _selectedMonth)),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: const Icon(Icons.edit),
                        onTap: _pickMonth,
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Total Pendapatan
                  _buildIncomeCard(),
                  const SizedBox(height: 20),

                  // Barang Sering Terjual
                  _buildSection(
                    title: '🔥 Barang Paling Laris',
                    icon: Icons.trending_up,
                    color: Colors.orange,
                    items: _controller.topSelling,
                    emptyText: 'Belum ada data penjualan.',
                    itemBuilder: (item) =>
                        '${item['product_name']} — ${item['total_qty']}x',
                  ),
                  const SizedBox(height: 16),

                  // Daftar Barang Terjual (detail)
                  _buildSection(
                    title: '📋 Barang Terjual',
                    icon: Icons.shopping_cart,
                    color: Colors.green,
                    items: _controller.soldItems,
                    emptyText: 'Tidak ada transaksi di periode ini.',
                    itemBuilder: (item) =>
                        '${item['product_name']} — ${item['total_qty']} pcs (Rp ${NumberFormat('#,###').format(item['total_sales'])})',
                  ),
                  const SizedBox(height: 16),

                  // Stok Menipis
                  _buildSection(
                    title: '⚠️ Stok Menipis (≤ 5)',
                    icon: Icons.warning_amber,
                    color: Colors.red,
                    items: _controller.lowStock,
                    emptyText: 'Semua stok aman.',
                    itemBuilder: (item) =>
                        '${item['name']} (stok: ${item['stock']})',
                  ),
                  const SizedBox(height: 16),

                  // Stok Kosong
                  _buildSection(
                    title: '❌ Stok Habis',
                    icon: Icons.block,
                    color: Colors.grey,
                    items: _controller.outOfStock,
                    emptyText: 'Tidak ada barang kosong.',
                    itemBuilder: (item) => '${item['name']}',
                  ),
                  const SizedBox(height: 40),
                ],
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
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Pendapatan',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatted,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.monetization_on,
              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Map<String, dynamic>> items,
    required String emptyText,
    required String Function(Map<String, dynamic>) itemBuilder,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  emptyText,
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              )
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: Colors.grey),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          itemBuilder(item),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
