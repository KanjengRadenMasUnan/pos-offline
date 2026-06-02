import 'package:flutter/material.dart';
import 'package:smartcampus/models/product_model.dart';
import 'package:smartcampus/models/cart_item_model.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get totalAmount {
    int total = 0;
    for (var item in _items) {
      total += (item.product.price * item.qty);
    }
    return total;
  }

  void addToCart(Product product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);

    if (index != -1) {
      _items[index].qty++;
    } else {
      _items.add(CartItem(product: product));
    }

    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  void removeItem(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void addQuantity(int productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);

    if (index != -1) {
      _items[index].qty++;
      notifyListeners();
    }
  }

  void decreaseQuantity(int productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);

    if (index != -1) {
      if (_items[index].qty > 1) {
        _items[index].qty--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeOrDecrement(Product product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);

    if (index != -1) {
      if (_items[index].qty > 1) {
        _items[index].qty--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }
}
