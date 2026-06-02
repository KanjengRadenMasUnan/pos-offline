import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../widgets/scanner_view.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
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
  late CashierController _cashierController;

  // --- LIFECYCLE ---

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cashierController = context.read<CashierController>();
      _cashierController.fetchProductList();
      _cashierController.onShowMessage = _showSnackBar;
      _cashierController.onShowTransactionSuccess = _showSuccessDialog;
    });
  }

  @override
  void dispose() {
    _cashierController.onShowMessage = null;
    _cashierController.onShowTransactionSuccess = null;
    super.dispose();
  }

  // --- UI FEEDBACK HANDLERS ---

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(milliseconds: 1000),
      ),
    );
  }

  void _showSuccessDialog(String invoice, List<CartItem> items, int total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Column(
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 50),
              SizedBox(height: 10),
              Text("Transaksi Berhasil"),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow("ID Transaksi", "#$invoice"),
                  _detailRow(
                    "Tanggal",
                    DateTime.now().toString().substring(0, 16),
                  ),
                  const Divider(),
                  const Text(
                    "Barang yang dibeli:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...items.map(_itemCard),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "TOTAL BAYAR",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        CurrencyFormat.convertToIdr(total, 0),
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      _cashierController.printReceipt(invoice, items, total);
                    },
                    icon: const Icon(Icons.print, color: AppTheme.primaryColor),
                    label: const Text(
                      "CETAK",
                      style: TextStyle(color: AppTheme.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      "TUTUP",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // --- WIDGET HELPERS ---

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "${item.qty} x ${CurrencyFormat.convertToIdr(item.product.price, 0)}",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormat.convertToIdr(item.qty * item.product.price, 0),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // --- MAIN BUILD ---

  @override
  Widget build(BuildContext context) {
    final isScanning = context.select<CashierController, bool>(
      (c) => c.isScanning,
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildBody(),
          if (isScanning)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(color: AppTheme.primaryColor),
                      SizedBox(height: 15),
                      Text(
                        "Memproses Kode...",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _buildScannerFAB(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text("Kasir Toko"),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _showSearchSheet(context),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: const [
        _PrinterStatusHeader(),
        Expanded(child: _CartContent()),
        _CheckoutPanel(),
      ],
    );
  }

  Widget _buildScannerFAB() {
    return Consumer2<CashierController, CartProvider>(
      builder: (_, cashierCtrl, cart, _) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 220),
          child: FloatingActionButton(
            backgroundColor: AppTheme.secondaryColor,
            child: const Icon(
              Icons.qr_code_scanner,
              color: Colors.white,
              size: 30,
            ),
            onPressed: () => _openScanner(context, cashierCtrl, cart),
          ),
        );
      },
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

// --- EXTERNAL FUNCTIONS ---

void _openScanner(
  BuildContext context,
  CashierController cashierCtrl,
  CartProvider cart,
) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ScannerView(
        onDetect: (String code) {
          cashierCtrl.handleScannedBarcodeWithDelay(code, cart);
        },
      ),
    ),
  );
}

// --- SUB-WIDGETS (PRIVAT) ---

class _PrinterStatusHeader extends StatelessWidget {
  const _PrinterStatusHeader();

  @override
  Widget build(BuildContext context) {
    return Consumer<CashierController>(
      builder: (_, controller, _) {
        return InkWell(
          onTap: controller.isPrinterLoading
              ? null
              : () => _showPrinterDialog(context, controller),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: controller.isPrinterConnected
                ? Colors.green[50]
                : Colors.orange[50],
            child: Row(
              children: [
                Icon(
                  controller.isPrinterConnected
                      ? Icons.print_rounded
                      : Icons.print_disabled,
                  color: controller.isPrinterConnected
                      ? Colors.green[700]
                      : Colors.orange[800],
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.isPrinterConnected
                            ? "Printer Terhubung"
                            : "Printer Terputus",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: controller.isPrinterConnected
                              ? Colors.green[800]
                              : Colors.orange[900],
                        ),
                      ),
                      Text(
                        controller.isPrinterConnected
                            ? controller.selectedDevice?.name ?? "Ready"
                            : "Ketuk untuk menyambungkan",
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                controller.isPrinterLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPrinterDialog(BuildContext context, CashierController controller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Pilih Printer"),
        content: SizedBox(
          width: double.maxFinite,
          child: controller.devices.isEmpty
              ? const Text("Tidak ada perangkat bluetooth.")
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: controller.devices.length,
                  itemBuilder: (_, i) => ListTile(
                    leading: const Icon(Icons.print),
                    title: Text(controller.devices[i].name),
                    subtitle: Text(controller.devices[i].macAdress),
                    onTap: () {
                      Navigator.pop(context);
                      controller.connectPrinter(controller.devices[i]);
                    },
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.initPrinter();
            },
            child: const Text("Scan Ulang"),
          ),
        ],
      ),
    );
  }
}

class _CartContent extends StatelessWidget {
  const _CartContent();

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (_, cart, _) {
        if (cart.items.isEmpty) {
          return const _EmptyCartView();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: cart.items.length,
          itemBuilder: (_, i) => _CartItemTile(item: cart.items[i]),
        );
      },
    );
  }
}

class _CheckoutPanel extends StatelessWidget {
  const _CheckoutPanel();

  @override
  Widget build(BuildContext context) {
    return Consumer2<CartProvider, CashierController>(
      builder: (_, cart, cashierCtrl, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    "Cetak Struk",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    cashierCtrl.withStruk
                        ? "Printer wajib konek"
                        : "Simpan tanpa print",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  value: cashierCtrl.withStruk,
                  activeThumbColor: AppTheme.primaryColor,
                  onChanged: cashierCtrl.toggleStrukOption,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total Tagihan",
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      CurrencyFormat.convertToIdr(cart.totalAmount, 0),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: cart.items.isEmpty
                        ? null
                        : () => cashierCtrl.processCheckout(cart),
                    child: const Text("PROSES PEMBAYARAN"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: ValueKey(item.product.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          dismissible: DismissiblePane(
            onDismissed: () => cart.removeItem(item.product.id),
          ),
          children: [
            SlidableAction(
              onPressed: (_) => cart.removeItem(item.product.id),
              backgroundColor: const Color(0xFFFE4A49),
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Hapus',
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
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
                    Text(
                      "@ ${CurrencyFormat.convertToIdr(item.product.price, 0)}",
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, color: Colors.red),
                    onPressed: () => cart.removeOrDecrement(item.product),
                  ),
                  Text(
                    "${item.qty}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.green),
                    onPressed: () => cart.addToCart(item.product),
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

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            "Keranjang Kosong",
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
