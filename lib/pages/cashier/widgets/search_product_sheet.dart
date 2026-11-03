import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/app_theme.dart';
import '../../../controllers/cashier_controller.dart';
import '../../../models/product_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../utils/currency_format.dart';

class SearchProductSheet extends StatefulWidget {
  const SearchProductSheet({super.key});

  @override
  State<SearchProductSheet> createState() => _SearchProductSheetState();
}

class _SearchProductSheetState extends State<SearchProductSheet> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeSearch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _initializeSearch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CashierController>().clearSearch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 32,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBorderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 10),
                    _buildSearchField(),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.cardBorderColor),
              Expanded(child: _buildSearchResults(scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 3, height: 12, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'CARI PRODUK CEPAT',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppTheme.surfaceRecessed,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.cardBorderColor),
            ),
            child: const Icon(Icons.close, size: 14, color: AppTheme.textPrimary),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: AppTheme.surfaceRecessed,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.cardBorderColor),
      ),
      child: TextField(
        controller: _searchCtrl,
        autofocus: true,
        style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Ketik nama atau scan barcode...',
          hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12),
          prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textSecondary),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16, color: AppTheme.textSecondary),
                  onPressed: () {
                    _searchCtrl.clear();
                    context.read<CashierController>().clearSearch();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        ),
        onChanged: (value) {
          setState(() {});
          context.read<CashierController>().searchProducts(value);
        },
      ),
    );
  }

  Widget _buildSearchResults(ScrollController scrollController) {
    return Consumer2<CashierController, CartProvider>(
      builder: (context, cashierCtrl, cart, _) {
        final results = cashierCtrl.searchResults;

        if (_searchCtrl.text.isEmpty) {
          return _buildEmptySearchState();
        }

        if (results.isEmpty) {
          return _buildNoResultsState();
        }

        return ListView.separated(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: results.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            return _buildProductItem(
              context,
              results[index],
              cashierCtrl,
              cart,
            );
          },
        );
      },
    );
  }

  Widget _buildProductItem(
    BuildContext context,
    Product product,
    CashierController controller,
    CartProvider cart,
  ) {
    final remainingStock = _calculateRemainingStock(product, cart);
    final hasStock = remainingStock > 0;
    final isLowStock = remainingStock > 0 && remainingStock <= 5;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
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
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      CurrencyFormat.convertToIdr(product.price, 0),
                      style: GoogleFonts.jetBrainsMono(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceRecessed,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: !hasStock
                              ? AppTheme.errorColor.withValues(alpha: 0.4)
                              : AppTheme.cardBorderColor,
                        ),
                      ),
                      child: Text(
                        !hasStock
                            ? 'HABIS'
                            : (isLowStock ? 'SISA $remainingStock' : 'STOK: $remainingStock'),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: !hasStock
                              ? AppTheme.errorColor
                              : (isLowStock ? AppTheme.warningColor : AppTheme.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: hasStock ? AppTheme.primaryColor : const Color(0xFFCBD5E1),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: hasStock
                ? () {
                    HapticFeedback.lightImpact();
                    controller.addToCartFromSearch(product, cart);
                  }
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, size: 15),
                const SizedBox(width: 4),
                Text(
                  "PILIH",
                  style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.keyboard_alt_outlined, size: 36, color: AppTheme.textMuted),
          const SizedBox(height: 10),
          Text(
            'Ketik nama atau barcode barang untuk mencari',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 36, color: AppTheme.textMuted),
          const SizedBox(height: 10),
          Text(
            'Barang tidak ditemukan dalam inventori',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  int _calculateRemainingStock(Product product, CartProvider cart) {
    try {
      final cartItem = cart.items.firstWhere(
        (item) => item.product.id == product.id,
      );
      return product.stock - cartItem.qty;
    } catch (_) {
      return product.stock;
    }
  }
}
