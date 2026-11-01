import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        ..initPrinter(),
      child: Builder(
        builder: (context) {
          final controller = Provider.of<HistoryController>(
            context,
            listen: false,
          );
          controller.onShowMessage = (message, color) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                backgroundColor: color,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                duration: const Duration(seconds: 2),
              ),
            );
          };
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            appBar: _buildAppBar(context),
            body: const _HistoryBody(),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        "Riwayat Transaksi",
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 17,
          color: AppTheme.textPrimary,
          letterSpacing: -0.2,
        ),
      ),
      actions: const [
        _RefreshButton(),
        SizedBox(width: 8),
      ],
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
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.primaryColor,
              ),
            ),
          );
        }

        if (controller.transactions.isEmpty) {
          return const EmptyData(
            message: "Tidak ada transaksi pada periode ini",
            icon: Icons.calendar_today_outlined,
          );
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: controller.transactions.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _TransactionCard(
            transaction: controller.transactions[i],
          ),
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
        final isFiltered = controller.selectedDateRange != null;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppTheme.cardBorderColor, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "PERIODE LAPORAN",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      controller.filterStatusText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isFiltered)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.close, size: 16, color: AppTheme.errorColor),
                  ),
                  tooltip: "Reset Filter",
                  onPressed: controller.resetFilter,
                ),
              const SizedBox(width: 6),
              OutlinedButton.icon(
                onPressed: () => _showDatePicker(context, controller),
                icon: const Icon(Icons.calendar_month_outlined, size: 16),
                label: Text(isFiltered ? "Ubah" : "Filter Tanggal"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  side: const BorderSide(color: AppTheme.cardBorderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
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
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.cardBorderColor),
            ),
            child: const Icon(
              Icons.refresh_rounded,
              size: 18,
              color: AppTheme.textPrimary,
            ),
          ),
          tooltip: "Refresh Riwayat",
          onPressed: () {
            HapticFeedback.lightImpact();
            controller.loadHistory();
          },
        );
      },
    );
  }
}

// --- TRANSACTION CARD ---
class _TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<HistoryController>(context, listen: false);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.lightImpact();
          _showTransactionDetail(context, transaction, controller);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorderColor, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_outlined,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          transaction.invoiceNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "${transaction.items.length} item",
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      transaction.createdAt,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormat.convertToIdr(transaction.totalAmount, 0),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "Lunas",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.successColor,
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
          primaryColor: AppTheme.primaryDark,
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primaryDark,
            surface: Colors.white,
          ),
        ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    controller.applyDateFilter(picked);
  }
}

void _showTransactionDetail(
  BuildContext context,
  TransactionModel transaction,
  HistoryController controller,
) {
  bool isPrinting = false;

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Detail Transaksi",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.invoiceNumber,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: AppTheme.textSecondary),
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.cardBorderColor),
                    ),
                    child: Column(
                      children: [
                        _detailRow("ID Transaksi", "#${transaction.id}"),
                        const SizedBox(height: 4),
                        _detailRow("Waktu", transaction.createdAt),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Daftar Item Dibeli:",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...transaction.items.map(_itemCard),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "TOTAL PEMBAYARAN",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        CurrencyFormat.convertToIdr(transaction.totalAmount, 0),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppTheme.cardBorderColor),
                    ),
                    child: const Text("Tutup", style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppTheme.primaryDark,
                    ),
                    onPressed: isPrinting
                        ? null
                        : () async {
                            setState(() => isPrinting = true);
                            Navigator.pop(dialogContext);
                            await controller.reprintTransaction(transaction);
                          },
                    icon: isPrinting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.print_rounded, size: 16),
                    label: Text(
                      isPrinting ? "Mencetak..." : "Cetak Ulang",
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

Widget _detailRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
      Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: AppTheme.textPrimary,
        ),
      ),
    ],
  );
}

Widget _itemCard(TransactionItemModel item) {
  return Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.cardBorderColor),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                "${item.qty}x @ ${CurrencyFormat.convertToIdr(item.price, 0)}",
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        Text(
          CurrencyFormat.convertToIdr(item.subtotal, 0),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    ),
  );
}
