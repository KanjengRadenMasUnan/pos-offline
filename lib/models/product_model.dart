class Product {
  final int id;
  final String code;
  final String name;
  final int price;
  final int stock;
  final String category;

  Product({
    required this.id,
    required this.code,
    required this.name,
    required this.price,
    required this.stock,
    required this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Tanpa Nama',
      price: json['price'] is int
          ? json['price']
          : int.parse(json['price'].toString()),
      stock: json['stock'] is int
          ? json['stock']
          : int.parse(json['stock'].toString()),
      category: json['category']?.toString() ?? 'Umum',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'price': price,
      'stock': stock,
      'category': category,
    };
  }
}
