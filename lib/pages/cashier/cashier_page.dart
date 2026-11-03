import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/scanner_view.dart';
import '../../controllers/cashier_controller.dart';
import '../../controllers/tablet_mode_controller.dart';
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
  String _tabletSearchQuery = '';
  String _tabletSelectedCategory = 'Semua';

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
    final isTablet = context.watch<TabletModeController>().isTabletLayout(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(isTablet),
      body: Stack(
        children: [
          if (isTablet)
            _buildTabletLayout()
          else
            _buildPortraitLayout(),
          if (context.select<CashierController, bool>((c) => c.isScanning))
            const _ScanningOverlay(),
        ],
      ),
    );
  }

  AppBar _buildAppBar(bool isTablet) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Kasir Toko",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              if (isTablet) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceRecessed,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.cardBorderColor),
                  ),
                  child: Text(
                    "TABLET STATION",
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
          Consumer<CartProvider>(
            builder: (_, cart, _) => Text(
              cart.items.isEmpty
                  ? "KERANJANG KOSONG // SIAP TRANSAKSI"
                  : "${cart.totalQty} ITEM DALAM KERANJANG",
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: cart.items.isEmpty ? AppTheme.textMuted : AppTheme.successColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (!isTablet)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.surfaceRecessed,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.cardBorderColor),
              ),
              child: const Icon(
                Icons.search_rounded,
                size: 18,
                color: AppTheme.textPrimary,
              ),
            ),
            tooltip: "Cari Produk",
            onPressed: () => _showSearchSheet(context),
          ),
        Consumer2<CashierController, CartProvider>(
          builder: (_, cashier, cart, _) => IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                size: 18,
                color: Colors.white,
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

  // --- PORTRAIT LAYOUT ---
  Widget _buildPortraitLayout() {
    return Column(
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
        const _CheckoutDock(),
      ],
    );
  }

  // --- TABLET HORIZONTAL 2-PANE LAYOUT ---
  Widget _buildTabletLayout() {
    return Column(
      children: [
        const _PrinterStatusBar(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // LEFT PANE: Product Fast-Tap Catalog (60% width)
              Expanded(
                flex: 6,
                child: _buildTabletCatalogPane(),
              ),

              // VERTICAL DIVIDER
              Container(width: 1, color: AppTheme.cardBorderColor),

              // RIGHT PANE: Live Bill & Checkout Console (40% width)
              Expanded(
                flex: 4,
                child: _buildTabletBillPane(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletCatalogPane() {
    return Consumer2<CashierController, CartProvider>(
      builder: (_, cashier, cart, _) {
        final allProducts = cashier.allProducts;

        // Categories
        final categories = <String>{'Semua'};
        for (var p in allProducts) {
          if (p.category.isNotEmpty) categories.add(p.category);
        }

        // Filter products
        final filtered = allProducts.where((p) {
          final matchesSearch = _tabletSearchQuery.isEmpty ||
              p.name.toLowerCase().contains(_tabletSearchQuery.toLowerCase()) ||
              p.code.toLowerCase().contains(_tabletSearchQuery.toLowerCase());
          final matchesCat = _tabletSelectedCategory == 'Semua' ||
              p.category.toLowerCase() == _tabletSelectedCategory.toLowerCase();
          return matchesSearch && matchesCat;
        }).toList();

        return Container(
          color: AppTheme.backgroundColor,
          child: Column(
            children: [
              // Search & Filter Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                color: Colors.white,
                child: Column(
                  children: [
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.cardBorderColor),
                      ),
                      child: TextField(
                        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText: "Cari produk dengan nama atau scan kode...",
                          hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textSecondary),
                          suffixIcon: _tabletSearchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () => setState(() => _tabletSearchQuery = ''),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() => _tabletSearchQuery = v.trim()),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Horizontal Category Chips
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: categories.map((cat) {
                          final isSelected = _tabletSelectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() => _tabletSelectedCategory = cat);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.primaryDark : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.primaryDark : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Product Touch Grid
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.inventory_2_outlined, size: 40, color: AppTheme.textMuted),
                            SizedBox(height: 8),
                            Text(
                              "Tidak ada produk yang cocok",
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.25,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (_, index) {
                          final product = filtered[index];
                          final cartItem = cart.items.cast<CartItem?>().firstWhere(
                                (item) => item?.product.id == product.id,
                                orElse: () => null,
                              );
                          final qtyInCart = cartItem?.qty ?? 0;
                          final hasStock = product.stock > qtyInCart;

                          return Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: hasStock
                                  ? () {
                                      HapticFeedback.lightImpact();
                                      cart.addToCart(product);
                                    }
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: qtyInCart > 0
                                        ? AppTheme.primaryColor
                                        : AppTheme.cardBorderColor,
                                    width: qtyInCart > 0 ? 1.5 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                product.name,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                            ),
                                            if (qtyInCart > 0)
                                              Container(
                                                margin: const EdgeInsets.only(left: 4),
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryColor,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  "$qtyInCart",
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          product.category,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          CurrencyFormat.convertToIdr(product.price, 0),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                        Text(
                                          product.stock <= 0
                                              ? "Habis"
                                              : "Stok: ${product.stock - qtyInCart}",
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: product.stock <= 0
                                                ? AppTheme.errorColor
                                                : AppTheme.textSecondary,
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
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabletBillPane() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Order Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.cardBorderColor, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 18, color: AppTheme.textPrimary),
                    SizedBox(width: 8),
                    Text(
                      "Pesanan Berjalan",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                Consumer<CartProvider>(
                  builder: (_, cart, _) => cart.items.isNotEmpty
                      ? InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            cart.clearCart();
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Text(
                              "Kosongkan",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.errorColor,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Scrollable Cart List
          Expanded(
            child: Consumer<CartProvider>(
              builder: (_, cart, _) {
                if (cart.items.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app_outlined, size: 36, color: AppTheme.textMuted),
                        SizedBox(height: 8),
                        Text(
                          "Pilih produk di sebelah kiri\nuntuk menambahkan ke pesanan",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (_, i) => _CartItemTile(item: cart.items[i]),
                );
              },
            ),
          ),

          // Integrated Checkout Panel at bottom of right pane
          const _CheckoutConsole(),
        ],
      ),
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

// ==================== CHECKOUT CONSOLE (REUSABLE IN TABLET & DOCK) ====================
class _CheckoutConsole extends StatefulWidget {
  const _CheckoutConsole();

  @override
  State<_CheckoutConsole> createState() => _CheckoutConsoleState();
}

class _CheckoutConsoleState extends State<_CheckoutConsole> {
  final TextEditingController _cashCtrl = TextEditingController();

  @override
  void dispose() {
    _cashCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CartProvider, CashierController>(
      builder: (_, cart, cashier, _) {
        final total = cart.totalAmount;
        final change = cashier.calculateChange(total);
        final canPay = cart.items.isNotEmpty && cashier.isPaymentSufficient(total);

        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceColor,
            border: Border(
              top: BorderSide(color: AppTheme.cardBorderColor, width: 1),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row 1: Total & Struk
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TOTAL TAGIHAN",
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        CurrencyFormat.convertToIdr(total, 0),
                        style: GoogleFonts.jetBrainsMono(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: -0.5,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => cashier.toggleStrukOption(!cashier.withStruk),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cashier.withStruk
                            ? AppTheme.primaryColor
                            : AppTheme.surfaceRecessed,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: cashier.withStruk
                              ? AppTheme.primaryColor
                              : AppTheme.cardBorderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_rounded,
                            size: 13,
                            color: cashier.withStruk
                                ? Colors.white
                                : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "STRUK",
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: cashier.withStruk
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Row 2: Cash Input & Quick Cash Buttons
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceRecessed,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.cardBorderColor),
                      ),
                      child: TextField(
                        controller: _cashCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: cashier.updateCashReceived,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Nominal tunai',
                          hintStyle: GoogleFonts.jetBrainsMono(color: AppTheme.textMuted, fontSize: 11),
                          prefixIcon: const Icon(
                            Icons.payments_outlined,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          suffixIcon: _cashCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 14),
                                  onPressed: () {
                                    _cashCtrl.clear();
                                    cashier.clearPayment();
                                  },
                                )
                              : null,
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 9,
                            horizontal: 8,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 6,
                    child: SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _QuickCashPill(label: "PAS", amount: total, controller: _cashCtrl),
                          _QuickCashPill(label: "50k", amount: 50000, controller: _cashCtrl),
                          _QuickCashPill(label: "100k", amount: 100000, controller: _cashCtrl),
                          _QuickCashPill(label: "200k", amount: 200000, controller: _cashCtrl),
                          _QuickCashPill(label: "500k", amount: 500000, controller: _cashCtrl),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Row 3: Kembalian & Bayar
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "KEMBALIAN",
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          CurrencyFormat.convertToIdr(change, 0),
                          style: GoogleFonts.jetBrainsMono(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
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
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 6,
                    child: SizedBox(
                      height: 42,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canPay
                              ? AppTheme.primaryColor
                              : const Color(0xFFCBD5E1),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
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
                            const Icon(Icons.check_rounded, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              "BAYAR (${cart.totalQty})",
                              style: GoogleFonts.jetBrainsMono(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                letterSpacing: 0.4,
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
        );
      },
    );
  }
}

// ==================== CHECKOUT DOCK (PORTRAIT ONLY) ====================
class _CheckoutDock extends StatelessWidget {
  const _CheckoutDock();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          border: Border(
            top: BorderSide(color: AppTheme.cardBorderColor, width: 1),
          ),
        ),
        child: const SafeArea(
          top: false,
          child: _CheckoutConsole(),
        ),
      ),
    );
  }
}

// ==================== PRINTER STATUS BAR (MINIMALIST) ====================
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceColor,
              border: Border(
                bottom: BorderSide(color: AppTheme.cardBorderColor, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: connected ? AppTheme.successColor : AppTheme.textMuted,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        connected ? "PRINTER AKTIF: " : "PRINTER OFFLINE: ",
                        style: GoogleFonts.jetBrainsMono(
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          color: AppTheme.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          connected
                              ? (ctrl.selectedDevice?.name ?? "Thermal Ready (58mm)")
                              : "Ketuk untuk hubungkan bluetooth",
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: connected
                                ? AppTheme.textSecondary
                                : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (ctrl.isPrinterLoading)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Row(
          children: [
            const Icon(Icons.print_rounded, color: AppTheme.primaryColor, size: 18),
            const SizedBox(width: 8),
            Text(
              "Perangkat Printer Bluetooth",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ctrl.devices.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bluetooth_searching, size: 32, color: AppTheme.textMuted),
                      const SizedBox(height: 10),
                      Text(
                        "Tidak ada printer bluetooth terdeteksi.\nPastikan bluetooth aktif dan printer menyala.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: ctrl.devices.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    leading: const Icon(Icons.print_outlined, color: AppTheme.textPrimary, size: 18),
                    title: Text(
                      ctrl.devices[i].name,
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    subtitle: Text(
                      ctrl.devices[i].macAdress,
                      style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: AppTheme.textMuted),
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
            child: Text("Tutup", style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () {
              Navigator.pop(context);
              ctrl.initPrinter();
            },
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: Text("Scan Ulang", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
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
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          HapticFeedback.lightImpact();
          controller.text = amount.toString();
          cashier.updateCashReceived(amount.toString());
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.surfaceRecessed,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.cardBorderColor),
          ),
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
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

    return Slidable(
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
              right: Radius.circular(8),
            ),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(8),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        CurrencyFormat.convertToIdr(item.product.price * item.qty, 0),
                        style: GoogleFonts.jetBrainsMono(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "@ ${CurrencyFormat.convertToIdr(item.product.price, 0)}",
                        style: GoogleFonts.jetBrainsMono(
                          color: AppTheme.textMuted,
                          fontSize: 10,
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
                color: AppTheme.surfaceRecessed,
                borderRadius: BorderRadius.circular(6),
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
                    constraints: const BoxConstraints(minWidth: 22),
                    alignment: Alignment.center,
                    child: Text(
                      '${item.qty}',
                      style: GoogleFonts.jetBrainsMono(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.7,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
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
                "Transaksi Berhasil!",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorderColor),
                ),
                child: Column(
                  children: [
                    ...items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
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
                    const Divider(height: 14),
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
                            fontSize: 15,
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
                  padding: const EdgeInsets.symmetric(vertical: 11),
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
                  padding: const EdgeInsets.symmetric(vertical: 11),
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
