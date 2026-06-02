import 'product_model.dart'; // Import file produk

class CartItem {
  final Product product;
  int qty;

  CartItem({required this.product, this.qty = 1});

  int get subtotal => product.price * qty;
}
