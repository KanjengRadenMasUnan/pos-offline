import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/history_controller.dart';
import '../../config/app_theme.dart';
import '../../utils/currency_format.dart';
import '../../widgets/empty_data.dart';
import '../../models/transaction_model.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HistoryController()
        ..loadHistory()
        ..initPrinter(), // Inisialisasi printer saat halaman dibuat
      child: Builder(
        builder: (context) {
          // Daftarkan callback snackbar ke controller
          final controller = Provider.of<HistoryController>(
            context,
            listen: false,
          );
          controller.onShowMessage = (message, color) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: color,
                duration: const Duration(seconds: 2),
              ),
            );
          };
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            appBar: _buildAppBar(),
            body: const _HistoryBody(),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text("Riwayat Transaksi"),
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      actions: const [_RefreshButton()],
    );
  }
}

// --- MAIN BODY COMPONENTS ---

class _HistoryBody extends StatelessWidget {
  const _HistoryBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        // (Opsional) Header status printer bisa ditambahkan di sini tanpa mengubah filter
        // _HistoryPrinterStatusHeader(), // Uncomment jika ingin seperti Kasir
        _FilterHeader(),
        Expanded(child: _TransactionList()),
      ],
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList();

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryController>(
      builder: (_, controller, _) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.transactions.isEmpty) {
          return const EmptyData(
            message: "Tidak ada transaksi pada periode ini",
            icon: Icons.date_range_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: controller.transactions.length,
          itemBuilder: (_, i) =>
              _TransactionCard(transaction: controller.transactions[i]),
        );
      },
    );
  }
}

// --- FILTER & HEADER COMPONENTS ---

class _FilterHeader extends StatelessWidget {
  const _FilterHeader();

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryController>(
      builder: (_, controller, _) {
        return Container(
          padding: const EdgeInsets.all(15),
          decoration: _headerDecoration(),
          child: Row(
            children: [
              _FilterInfo(controller: controller),
              if (controller.selectedDateRange != null)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: controller.resetFilter,
                ),
              ElevatedButton.icon(
                onPressed: () => _showDatePicker(context, controller),
                icon: const Icon(Icons.calendar_month, size: 18),
                label: const Text("Pilih Tanggal"),
                style: _datePickerButtonStyle(),
              ),
            ],
          ),
        );
      },
    );
  }

  BoxDecoration _headerDecoration() {
    return BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          blurRadius: 5,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  ButtonStyle _datePickerButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 15),
    );
  }
}

class _FilterInfo extends StatelessWidget {
  final HistoryController controller;
  const _FilterInfo({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Periode Laporan",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            controller.filterStatusText,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton();

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryController>(
      builder: (_, controller, _) {
        return IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: controller.loadHistory,
        );
      },
    );
  }
}

// --- TRANSACTION CARD & LIST ITEM ---

class _TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    // Ambil controller dari provider (listen: false agar tidak rebuild semua card)
    final controller = Provider.of<HistoryController>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => _showTransactionDetail(context, transaction, controller),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        leading: _buildIcon(),
        title: Text(
          transaction.invoiceNumber,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          transaction.createdAt,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Text(
          CurrencyFormat.convertToIdr(transaction.totalAmount, 0),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.green,
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.seedColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.receipt, color: AppTheme.primaryColor),
    );
  }
}

// --- DIALOGS & HELPER FUNCTIONS ---

Future<void> _showDatePicker(
  BuildContext context,
  HistoryController controller,
) async {
  final picked = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2020),
    lastDate: DateTime.now(),
    builder: (_, child) {
      return Theme(
        data: ThemeData.light().copyWith(
          primaryColor: AppTheme.primaryColor,
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryColor),
        ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    controller.applyDateFilter(picked);
  }
}

// Fungsi ini sekarang menerima HistoryController
void _showTransactionDetail(
  BuildContext context,
  TransactionModel transaction,
  HistoryController controller,
) {
  bool isPrinting = false; // State lokal untuk tombol loading

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Column(
            children: [
              const Text(
                "Detail Transaksi",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                transaction.invoiceNumber,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow("ID Transaksi", "#${transaction.id}"),
                  _detailRow("Tanggal", transaction.createdAt),
                  const Divider(),
                  const Text(
                    "Barang yang dibeli:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...transaction.items.map(_itemCard),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "TOTAL BAYAR",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        CurrencyFormat.convertToIdr(transaction.totalAmount, 0),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Tutup"),
            ),
            ElevatedButton.icon(
              onPressed: isPrinting
                  ? null // Disable tombol saat proses cetak
                  : () async {
                      setState(() => isPrinting = true);
                      // Tutup dialog agar tidak mengganggu
                      Navigator.pop(dialogContext);
                      // Panggil controller untuk mencetak
                      await controller.reprintTransaction(transaction);
                      // Set isPrinting = false tidak diperlukan karena dialog sudah ditutup
                    },
              icon: isPrinting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.print, size: 16),
              label: Text(isPrinting ? "Mencetak..." : "Cetak Ulang"),
            ),
          ],
        );
      },
    ),
  );
}

Widget _detailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

Widget _itemCard(TransactionItemModel item) {
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.productName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("${item.qty} x ${CurrencyFormat.convertToIdr(item.price, 0)}"),
            Text(
              CurrencyFormat.convertToIdr(item.subtotal, 0),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Text(
          "ID Produk: ${item.productId}",
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    ),
  );
}
