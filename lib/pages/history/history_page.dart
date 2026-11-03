import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/history_controller.dart';
import '../../controllers/tablet_mode_controller.dart';
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
      title: Row(
        children: [
          Text(
            "Riwayat Transaksi",
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w900,
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
              "LOGS",
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
      actions: const [
        _RefreshButton(),
        SizedBox(width: 8),
      ],
    );
  }
}

// --- MAIN BODY COMPONENTS ---
class _HistoryBody extends StatefulWidget {
  const _HistoryBody();

  @override
  State<_HistoryBody> createState() => _HistoryBodyState();
}

class _HistoryBodyState extends State<_HistoryBody> {
  TransactionModel? _selectedTransaction;

  @override
  Widget build(BuildContext context) {
    final isTablet = context.watch<TabletModeController>().isTabletLayout(context);

    if (isTablet) {
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

          // Auto-select first transaction if none selected or not in list
          if (_selectedTransaction == null ||
              !controller.transactions.any((t) => t.id == _selectedTransaction!.id)) {
            _selectedTransaction = controller.transactions.first;
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // LEFT PANE (42%): Filter & Transaction List
              Expanded(
                flex: 42,
                child: Column(
                  children: [
                    const _FilterHeader(),
                    Expanded(
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                        itemCount: controller.transactions.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (_, i) {
                          final tx = controller.transactions[i];
                          final isSelected = _selectedTransaction?.id == tx.id;
                          return _TransactionCard(
                            transaction: tx,
                            isSelected: isSelected,
                            onTap: () => setState(() => _selectedTransaction = tx),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // DIVIDER
              Container(width: 1, color: AppTheme.cardBorderColor),

              // RIGHT PANE (58%): Transaction Digital Receipt
              Expanded(
                flex: 58,
                child: _TransactionReceiptPane(
                  transaction: _selectedTransaction!,
                  controller: controller,
                ),
              ),
            ],
          );
        },
      );
    }

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceColor,
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
                    Text(
                      "PERIODE LAPORAN",
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      controller.filterStatusText,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
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
                      color: AppTheme.surfaceRecessed,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.close, size: 14, color: AppTheme.errorColor),
                  ),
                  tooltip: "Reset Filter",
                  onPressed: controller.resetFilter,
                ),
              const SizedBox(width: 6),
              OutlinedButton.icon(
                onPressed: () => _showDatePicker(context, controller),
                icon: const Icon(Icons.calendar_month_outlined, size: 15),
                label: Text(isFiltered ? "Ubah" : "Filter Tanggal"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  side: const BorderSide(color: AppTheme.cardBorderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  textStyle: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w700),
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
              color: AppTheme.surfaceRecessed,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.cardBorderColor),
            ),
            child: const Icon(
              Icons.refresh_rounded,
              size: 16,
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
  final bool isSelected;
  final VoidCallback? onTap;

  const _TransactionCard({
    required this.transaction,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<HistoryController>(context, listen: false);

    return Material(
      color: AppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          HapticFeedback.lightImpact();
          if (onTap != null) {
            onTap!();
          } else {
            _showTransactionDetail(context, transaction, controller);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.surfaceRecessed
                : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : AppTheme.cardBorderColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceRecessed,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.cardBorderColor),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: AppTheme.primaryColor,
                  size: 18,
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
                          style: GoogleFonts.jetBrainsMono(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceRecessed,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "${transaction.items.length} ITEM",
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      transaction.createdAt,
                      style: GoogleFonts.jetBrainsMono(
                        color: AppTheme.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormat.convertToIdr(transaction.totalAmount, 0),
                    style: GoogleFonts.jetBrainsMono(
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                      color: AppTheme.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.successColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "LUNAS",
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
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

// --- TABLET RECEIPT PANE ---
class _TransactionReceiptPane extends StatefulWidget {
  final TransactionModel transaction;
  final HistoryController controller;

  const _TransactionReceiptPane({
    required this.transaction,
    required this.controller,
  });

  @override
  State<_TransactionReceiptPane> createState() => _TransactionReceiptPaneState();
}

class _TransactionReceiptPaneState extends State<_TransactionReceiptPane> {
  bool _isPrinting = false;

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Receipt
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Detail Nota Transaksi",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tx.invoiceNumber,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryDark,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isPrinting
                    ? null
                    : () async {
                        setState(() => _isPrinting = true);
                        await widget.controller.reprintTransaction(tx);
                        if (mounted) setState(() => _isPrinting = false);
                      },
                icon: _isPrinting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.print_rounded, size: 16),
                label: Text(
                  _isPrinting ? "Mencetak..." : "Cetak Ulang Struk",
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Metadata row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.cardBorderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _detailRow("ID Transaksi", "#${tx.id}"),
                _detailRow("Waktu", tx.createdAt),
                _detailRow("Total Item", "${tx.items.length} Barang"),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Items Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 5, child: Text("NAMA BARANG", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textSecondary))),
                Expanded(flex: 2, child: Text("QTY", textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textSecondary))),
                Expanded(flex: 3, child: Text("HARGA", textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textSecondary))),
                Expanded(flex: 3, child: Text("SUBTOTAL", textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textSecondary))),
              ],
            ),
          ),

          // Items Scrollable List
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: tx.items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final item = tx.items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text(
                          item.productName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "${item.qty}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          CurrencyFormat.convertToIdr(item.price, 0),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          CurrencyFormat.convertToIdr(item.subtotal, 0),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Total Bar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.cardBorderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "TOTAL PEMBAYARAN",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  CurrencyFormat.convertToIdr(tx.totalAmount, 0),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
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
