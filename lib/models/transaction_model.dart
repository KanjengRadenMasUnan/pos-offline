class TransactionModel {
  final int id;
  final String transactionId;
  final String invoiceNumber;
  final int totalAmount;
  final String createdAt;
  final List<TransactionItemModel> items;

  TransactionModel({
    required this.id,
    required this.transactionId,
    required this.invoiceNumber,
    required this.totalAmount,
    required this.createdAt,
    required this.items,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List? ?? [];

    final parsedItems = itemsList
        .map((item) => TransactionItemModel.fromJson(item))
        .toList();

    return TransactionModel(
      id: json['id'] as int? ?? 0,
      transactionId: json['transaction_id']?.toString() ?? '-',
      invoiceNumber: json['invoice_number']?.toString() ?? '-',
      totalAmount: int.tryParse(json['total_amount'].toString()) ?? 0,
      createdAt: json['created_at']?.toString() ?? '-',
      items: parsedItems,
    );
  }
}

class TransactionItemModel {
  final int productId;
  final String productName;
  final int price;
  final int qty;
  final int subtotal;

  TransactionItemModel({
    required this.productId,
    required this.productName,
    required this.price,
    required this.qty,
    required this.subtotal,
  });

  factory TransactionItemModel.fromJson(Map<String, dynamic> json) {
    return TransactionItemModel(
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? 'Tanpa Nama',
      price: json['price'] ?? 0,
      qty: json['qty'] ?? 0,
      subtotal: json['subtotal'] ?? 0,
    );
  }
}
