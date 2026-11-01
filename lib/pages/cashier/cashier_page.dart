import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../widgets/scanner_view.dart';
import '../../controllers/cashier_controller.dart';
import '../../providers/cart_provider.dart';
import '../../models/cart_item_model.dart';
import '../../utils/currency_format.dart';
import '../../config/app_theme.dart';
import 'widgets/search_product_sheet.dart';

class CashierPage extends StatefulWidget {
  const CashierPage({super.key});

  @override
  State<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends State<CashierPage> {
  late final CashierController _cashierCtrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cashierCtrl = context.read<CashierController>();
      _cashierCtrl.fetchProductList();
      _cashierCtrl.onShowMessage = _showSnackBar;
      _cashierCtrl.onShowTransactionSuccess = _showSuccessDialog;
    });
  }

  @override
  void dispose() {
    _cashierCtrl.onShowMessage = null;
    _cashierCtrl.onShowTransactionSuccess = null;
    super.dispose();
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(milliseconds: 1400),
        ),
      );
  }

  void _showSuccessDialog(String invoice, List<CartItem> items, int total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _TransactionSuccessDialog(
        invoice: invoice,
        items: items,
        total: total,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              const _PrinterStatusBar(),
              Expanded(
                child: Consumer<CartProvider>(
                  builder: (_, cart, _) {
                    if (cart.items.isEmpty) return const _EmptyCartView();
                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 180),
                      itemCount: cart.items.length,
                      itemBuilder: (_, i) => _CartItemTile(item: cart.items[i]),
                    );
                  },
                ),
              ),
            ],
          ),
          const _CheckoutDock(),
          if (context.select<CashierController, bool>((c) => c.isScanning))
            const _ScanningOverlay(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Kasir Toko",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: AppTheme.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          Consumer<CartProvider>(
            builder: (_, cart, _) => Text(
              cart.items.isEmpty
                  ? "Keranjang kosong"
                  : "${cart.totalQty} barang di keranjang",
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
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
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.cardBorderColor),
            ),
            child: const Icon(
              Icons.search_rounded,
              size: 20,
              color: AppTheme.textPrimary,
            ),
          ),
          tooltip: "Cari Produk",
          onPressed: () => _showSearchSheet(context),
        ),
        Consumer2<CashierController, CartProvider>(
          builder: (_, cashier, cart, _) => IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                size: 20,
                color: AppTheme.primaryColor,
              ),
            ),
            tooltip: "Scan Barcode",
            onPressed: () => _openScanner(context, cashier, cart),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _showSearchSheet(BuildContext context) {
    final controller = context.read<CashierController>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: controller,
        child: const SearchProductSheet(),
      ),
    );
  }
}

// ==================== PRINTER STATUS BAR ====================
class _PrinterStatusBar extends StatelessWidget {
  const _PrinterStatusBar();

  @override
  Widget build(BuildContext context) {
    return Consumer<CashierController>(
      builder: (_, ctrl, _) {
        final connected = ctrl.isPrinterConnected;
        return InkWell(
          onTap: ctrl.isPrinterLoading ? null : () => _showPrinterList(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: connected
                  ? const Color(0xFFF0FDF4)
                  : const Color(0xFFFFFBEB),
              border: Border(
                bottom: BorderSide(
                  color: connected
                      ? const Color(0xFFBBF7D0)
                      : const Color(0xFFFDE68A),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: connected
                        ? AppTheme.successColor
                        : AppTheme.warningColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        connected ? "Printer Terhubung: " : "Printer Terputus: ",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: connected
                              ? const Color(0xFF166534)
                              : const Color(0xFF92400E),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          connected
                              ? (ctrl.selectedDevice?.name ?? "Thermal Ready")
                              : "Ketuk untuk menyambungkan",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: connected
                                ? const Color(0xFF15803D)
                                : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (ctrl.isPrinterLoading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppTheme.textMuted,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPrinterList(BuildContext context) {
    final ctrl = context.read<CashierController>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.print_rounded, color: AppTheme.primaryColor, size: 22),
            SizedBox(width: 10),
            Text(
              "Pilih Printer Bluetooth",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ctrl.devices.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.bluetooth_searching, size: 40, color: AppTheme.textMuted),
                      SizedBox(height: 12),
                      Text(
                        "Tidak ada printer bluetooth terdeteksi.\nPastikan bluetooth aktif dan printer menyala.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: ctrl.devices.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: const Icon(Icons.print_outlined, color: AppTheme.textPrimary),
                    title: Text(
                      ctrl.devices[i].name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      ctrl.devices[i].macAdress,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      ctrl.connectPrinter(ctrl.devices[i]);
                    },
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup", style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(context);
              ctrl.initPrinter();
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text("Scan Ulang"),
          ),
        ],
      ),
    );
  }
}

// ==================== CHECKOUT DOCK ====================
class _CheckoutDock extends StatefulWidget {
  const _CheckoutDock();

  @override
  State<_CheckoutDock> createState() => _CheckoutDockState();
}

class _CheckoutDockState extends State<_CheckoutDock> {
  final TextEditingController _cashCtrl = TextEditingController();

  @override
  void dispose() {
    _cashCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Consumer2<CartProvider, CashierController>(
        builder: (_, cart, cashier, _) {
          final total = cart.totalAmount;
          final change = cashier.calculateChange(total);
          final canPay = cart.items.isNotEmpty && cashier.isPaymentSufficient(total);

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Row 1: Total Amount & Struk Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "TOTAL TAGIHAN",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              CurrencyFormat.convertToIdr(total, 0),
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        // Struk toggle pill
                        InkWell(
                          onTap: () => cashier.toggleStrukOption(!cashier.withStruk),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: cashier.withStruk
                                  ? AppTheme.primaryColor.withValues(alpha: 0.08)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: cashier.withStruk
                                    ? AppTheme.primaryColor.withValues(alpha: 0.3)
                                    : AppTheme.cardBorderColor,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.receipt_rounded,
                                  size: 15,
                                  color: cashier.withStruk
                                      ? AppTheme.primaryColor
                                      : AppTheme.textMuted,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  "Cetak Struk",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: cashier.withStruk
                                        ? AppTheme.primaryColor
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  cashier.withStruk
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  size: 14,
                                  color: cashier.withStruk
                                      ? AppTheme.primaryColor
                                      : AppTheme.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Row 2: Cash Input & Quick Cash Buttons
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.cardBorderColor),
                            ),
                            child: TextField(
                              controller: _cashCtrl,
                              keyboardType: TextInputType.number,
                              onChanged: cashier.updateCashReceived,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Uang diterima',
                                hintStyle: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                ),
                                prefixIcon: const Icon(
                                  Icons.payments_outlined,
                                  size: 18,
                                  color: AppTheme.textSecondary,
                                ),
                                suffixIcon: _cashCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 16),
                                        onPressed: () {
                                          _cashCtrl.clear();
                                          cashier.clearPayment();
                                        },
                                      )
                                    : null,
                                isDense: true,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                  horizontal: 10,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 6,
                          child: SizedBox(
                            height: 42,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              children: [
                                _QuickCashPill(
                                  label: "Uang Pas",
                                  amount: total,
                                  controller: _cashCtrl,
                                ),
                                _QuickCashPill(
                                  label: "50 rb",
                                  amount: 50000,
                                  controller: _cashCtrl,
                                ),
                                _QuickCashPill(
                                  label: "100 rb",
                                  amount: 100000,
                                  controller: _cashCtrl,
                                ),
                                _QuickCashPill(
                                  label: "200 rb",
                                  amount: 200000,
                                  controller: _cashCtrl,
                                ),
                                _QuickCashPill(
                                  label: "500 rb",
                                  amount: 500000,
                                  controller: _cashCtrl,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Row 3: Kembalian & Bayar Button
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "KEMBALIAN",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                CurrencyFormat.convertToIdr(change, 0),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: canPay
                                      ? AppTheme.successColor
                                      : (cashier.cashReceived > 0
                                          ? AppTheme.errorColor
                                          : AppTheme.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 6,
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canPay
                                    ? AppTheme.primaryDark
                                    : const Color(0xFFCBD5E1),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: canPay
                                  ? () {
                                      HapticFeedback.heavyImpact();
                                      cashier.processCheckout(cart);
                                      _cashCtrl.clear();
                                    }
                                  : null,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_rounded, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    "BAYAR (${cart.totalQty})",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
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
        },
      ),
    );
  }
}

// --- QUICK CASH PILL ---
class _QuickCashPill extends StatelessWidget {
  final String label;
  final int amount;
  final TextEditingController controller;

  const _QuickCashPill({
    required this.label,
    required this.amount,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final cashier = context.read<CashierController>();
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          HapticFeedback.lightImpact();
          controller.text = amount.toString();
          cashier.updateCashReceived(amount.toString());
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.cardBorderColor),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== CART ITEM TILE ====================
class _CartItemTile extends StatelessWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Slidable(
        key: ValueKey(item.product.id),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.22,
          children: [
            SlidableAction(
              onPressed: (_) {
                HapticFeedback.mediumImpact();
                cart.removeItem(item.product.id);
              },
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              icon: Icons.delete_outline_rounded,
              label: 'Hapus',
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(12),
              ),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorderColor, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          CurrencyFormat.convertToIdr(item.product.price * item.qty, 0),
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "@ ${CurrencyFormat.convertToIdr(item.product.price, 0)}",
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.cardBorderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        cart.decreaseQuantity(item.product.id);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.remove, size: 14, color: AppTheme.textPrimary),
                      ),
                    ),
                    Container(
                      constraints: const BoxConstraints(minWidth: 24),
                      alignment: Alignment.center,
                      child: Text(
                        '${item.qty}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        cart.addQuantity(item.product.id);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.add, size: 14, color: AppTheme.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== EMPTY CART ====================
class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_basket_outlined,
              size: 52,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Keranjang Masih Kosong",
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Scan barcode produk atau ketuk tombol cari\ndi kanan atas untuk menambahkan barang",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== SCANNING OVERLAY ====================
class _ScanningOverlay extends StatelessWidget {
  const _ScanningOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.35),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.cardBorderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                  strokeWidth: 2.5,
                ),
              ),
              SizedBox(width: 14),
              Text(
                "Memproses Kode...",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== SUCCESS DIALOG ====================
class _TransactionSuccessDialog extends StatelessWidget {
  final String invoice;
  final List<CartItem> items;
  final int total;

  const _TransactionSuccessDialog({
    required this.invoice,
    required this.items,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final cashier = context.read<CashierController>();
    return AlertDialog(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.88,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.successColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Transaksi Berhasil",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Nota: #$invoice",
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Item breakdown container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.cardBorderColor),
                ),
                child: Column(
                  children: [
                    ...items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "${item.qty}x ${item.product.name}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              CurrencyFormat.convertToIdr(item.qty * item.product.price, 0),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "TOTAL BAYAR",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          CurrencyFormat.convertToIdr(total, 0),
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
            ],
          ),
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppTheme.cardBorderColor),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  cashier.printReceipt(invoice, items, total);
                },
                icon: const Icon(Icons.print_rounded, size: 16, color: AppTheme.textPrimary),
                label: const Text(
                  "Cetak Struk",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: AppTheme.primaryDark,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: const Text(
                  "Selesai",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ==================== SCANNER HELPER ====================
void _openScanner(
  BuildContext context,
  CashierController cashier,
  CartProvider cart,
) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ScannerView(
        onDetect: (code) => cashier.handleScannedBarcodeWithDelay(code, cart),
      ),
    ),
  );
}
