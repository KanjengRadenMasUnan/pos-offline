import 'package:flutter/material.dart';
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
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(milliseconds: 1000),
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
                  builder: (_, cart, __) {
                    if (cart.items.isEmpty) return const _EmptyCartView();
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
                      itemCount: cart.items.length,
                      itemBuilder: (_, i) => _CartItemTile(item: cart.items[i]),
                    );
                  },
                ),
              ),
            ],
          ),
          const _CheckoutPanel(),
          if (context.select<CashierController, bool>((c) => c.isScanning))
            const _ScanningOverlay(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        "Kasir Toko",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          tooltip: "Cari Produk",
          onPressed: () => _showSearchSheet(context),
        ),
        Consumer2<CashierController, CartProvider>(
          builder: (_, cashier, cart, __) => IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
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

// ==================== CHECKOUT PANEL ====================
class _CheckoutPanel extends StatelessWidget {
  const _CheckoutPanel();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.18,
      minChildSize: 0.18,
      maxChildSize: 0.45,
      snap: true,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.only(bottom: 20),
          child: const _CheckoutContent(),
        ),
      ),
    );
  }
}

class _CheckoutContent extends StatefulWidget {
  const _CheckoutContent();

  @override
  State<_CheckoutContent> createState() => _CheckoutContentState();
}

class _CheckoutContentState extends State<_CheckoutContent> {
  final TextEditingController _cashCtrl = TextEditingController();

  @override
  void dispose() {
    _cashCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CartProvider, CashierController>(
      builder: (_, cart, cashier, __) {
        final change = cashier.calculateChange(cart.totalAmount);
        final canPay =
            cart.items.isNotEmpty &&
            cashier.isPaymentSufficient(cart.totalAmount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total & Struk toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "TOTAL",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade500,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormat.convertToIdr(cart.totalAmount, 0),
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            "Struk",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: cashier.withStruk,
                              onChanged: cashier.toggleStrukOption,
                              activeColor: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Input uang & tombol cepat
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: TextField(
                          controller: _cashCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: cashier.updateCashReceived,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Uang diterima',
                            prefixIcon: const Icon(
                              Icons.payments_rounded,
                              size: 20,
                              color: AppTheme.primaryColor,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 5,
                        child: SizedBox(
                          height: 44,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _QuickCashBtn(
                                label: "PAS",
                                amount: cart.totalAmount,
                                controller: _cashCtrl,
                              ),
                              _QuickCashBtn(
                                label: "50K",
                                amount: 50000,
                                controller: _cashCtrl,
                              ),
                              _QuickCashBtn(
                                label: "100K",
                                amount: 100000,
                                controller: _cashCtrl,
                              ),
                              _QuickCashBtn(
                                label: "200K",
                                amount: 200000,
                                controller: _cashCtrl,
                              ),
                              _QuickCashBtn(
                                label: "500K",
                                amount: 500000,
                                controller: _cashCtrl,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Kembalian & tombol bayar
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Kembalian",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormat.convertToIdr(change, 0),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: change >= 0
                                    ? Colors.green.shade700
                                    : Colors.red.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            disabledBackgroundColor: Colors.grey.shade300,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(0, 46),
                          ),
                          onPressed: canPay
                              ? () => cashier.processCheckout(cart)
                              : null,
                          child: Text(
                            "BAYAR (${cart.items.length})",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuickCashBtn extends StatelessWidget {
  final String label;
  final int amount;
  final TextEditingController controller;

  const _QuickCashBtn({
    required this.label,
    required this.amount,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final cashier = context.read<CashierController>();
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          controller.text = amount.toString();
          cashier.updateCashReceived(amount.toString());
        },
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 12,
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Slidable(
        key: ValueKey(item.product.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) => cart.removeItem(item.product.id),
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              icon: Icons.delete_rounded,
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
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
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
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          CurrencyFormat.convertToIdr(
                            item.product.price * item.qty,
                            0,
                          ),
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "@ ${CurrencyFormat.convertToIdr(item.product.price, 0)}",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 16),
                      onPressed: () => cart.decreaseQuantity(item.product.id),
                    ),
                    Text(
                      '${item.qty}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16),
                      onPressed: () => cart.addQuantity(item.product.id),
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
          Icon(
            Icons.shopping_basket_outlined,
            size: 72,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            "Keranjang Belanja Kosong",
            style: TextStyle(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: connected ? Colors.green.shade50 : Colors.orange.shade50,
            child: Row(
              children: [
                Icon(
                  connected
                      ? Icons.print_rounded
                      : Icons.print_disabled_rounded,
                  size: 20,
                  color: connected
                      ? Colors.green.shade700
                      : Colors.orange.shade800,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        connected ? "Printer Terhubung" : "Printer Terputus",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: connected
                              ? Colors.green.shade800
                              : Colors.orange.shade900,
                        ),
                      ),
                      Text(
                        connected
                            ? (ctrl.selectedDevice?.name ?? "Siap")
                            : "Ketuk untuk sambungkan",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (ctrl.isPrinterLoading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: connected
                          ? Colors.green.shade700
                          : Colors.orange.shade800,
                    ),
                  )
                else
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: Colors.grey.shade600,
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
        title: const Text(
          "Pilih Printer",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ctrl.devices.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    "Tidak ada perangkat Bluetooth ditemukan.",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: ctrl.devices.length,
                  itemBuilder: (_, i) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.print_rounded),
                    title: Text(
                      ctrl.devices[i].name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(ctrl.devices[i].macAdress),
                    onTap: () {
                      Navigator.pop(context);
                      ctrl.connectPrinter(ctrl.devices[i]);
                    },
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ctrl.initPrinter();
            },
            child: const Text(
              "Scan Ulang",
              style: TextStyle(fontWeight: FontWeight.bold),
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
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Memproses Kode...",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black.withOpacity(0.8),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      title: const Column(
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
          SizedBox(height: 12),
          Text(
            "Transaksi Berhasil",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _InfoRow("ID Transaksi", "#$invoice"),
                    const SizedBox(height: 4),
                    _InfoRow(
                      "Tanggal",
                      DateTime.now().toString().substring(0, 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Barang yang dibeli:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...items.map((item) => _ReceiptItem(item: item)),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "TOTAL BAYAR",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    CurrencyFormat.convertToIdr(total, 0),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => cashier.printReceipt(invoice, items, total),
                icon: const Icon(
                  Icons.print_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                label: const Text(
                  "CETAK",
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppTheme.primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "TUTUP",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptItem extends StatelessWidget {
  final CartItem item;
  const _ReceiptItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${item.qty} x ${CurrencyFormat.convertToIdr(item.product.price, 0)}",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormat.convertToIdr(item.qty * item.product.price, 0),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
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
