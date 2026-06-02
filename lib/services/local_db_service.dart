import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

// Import model-model Anda
import '../models/product_model.dart';
import '../models/transaction_model.dart';
import '../models/cart_item_model.dart';

class LocalDbService {
  static final LocalDbService instance = LocalDbService._init();
  static Database? _database;

  LocalDbService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('nanda_cell.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // --- MEMBUAT TABEL DATABASE (Sama persis dengan Migrasi Laravel) ---
  Future _createDB(Database db, int version) async {
    // 1. Tabel Produk
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        price INTEGER NOT NULL,
        stock INTEGER NOT NULL,
        category TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');

    // 2. Tabel Transaksi Utama
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_no TEXT NOT NULL UNIQUE,
        total_amount INTEGER NOT NULL,
        transaction_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 3. Tabel Detail Transaksi
    await db.execute('''
      CREATE TABLE transaction_details (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        qty INTEGER NOT NULL,
        subtotal INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');
  }

  // =========================================================================
  // LOGIK MANAJEMEN PRODUK (CRUD & SOFT DELETES)
  // =========================================================================

  // Read: Mengambil semua produk yang BELUM di-softdelete
  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    final result = await db.query(
      'products',
      where: 'deleted_at IS NULL',
      orderBy: 'name ASC',
    );

    return result.map((json) => Product.fromJson(json)).toList();
  }

  // Search: Cari barang berdasarkan Nama atau Barcode
  Future<List<Product>> searchProducts(String query) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      '''
      SELECT * FROM products 
      WHERE deleted_at IS NULL 
      AND (name LIKE ? OR code LIKE ?)
    ''',
      ['%$query%', '%$query%'],
    );

    return result.map((json) => Product.fromJson(json)).toList();
  }

  // Get By Code: Cari satu barang spesifik (Untuk Scanner Kasir)
  Future<Product?> getProductByCode(String code) async {
    final db = await instance.database;
    final maps = await db.query(
      'products',
      where: 'code = ? AND deleted_at IS NULL',
      whereArgs: [code],
    );

    if (maps.isNotEmpty) {
      return Product.fromJson(maps.first);
    } else {
      return null;
    }
  }

  // Create: Tambah produk baru dengan Auto-Generate Kode (BRG-XXXX) jika kosong
  Future<Product?> addProduct(
    String name,
    int price,
    int stock,
    String category, {
    String? code,
  }) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    String finalCode = '';

    if (code != null && code.trim().isNotEmpty) {
      finalCode = code.trim();
    } else {
      // Logika penomoran otomatis BRG-XXXX seperti di Laravel ApiController
      final lastProduct = await db.rawQuery('''
        SELECT code FROM products 
        WHERE code LIKE 'BRG-%' 
        ORDER BY id DESC LIMIT 1
      ''');

      int number = 1;
      if (lastProduct.isNotEmpty) {
        final lastCode = lastProduct.first['code'].toString();
        final numericPart = lastCode.replaceAll('BRG-', '');
        number = (int.tryParse(numericPart) ?? 0) + 1;
      }
      finalCode = 'BRG-${number.toString().padLeft(4, '0')}';
    }

    final data = {
      'code': finalCode,
      'name': name,
      'price': price,
      'stock': stock,
      'category': category.isEmpty ? 'Umum' : category,
      'created_at': now,
      'updated_at': now,
    };

    final id = await db.insert('products', data);

    // Kembalikan objek produk yang baru dibuat
    return Product(
      id: id,
      code: finalCode,
      name: name,
      price: price,
      stock: stock,
      category: category.isEmpty ? 'Umum' : category,
    );
  }

  // Update: Mengubah informasi produk
  Future<bool> updateProduct(
    int id,
    String name,
    int price,
    int stock,
    String category,
  ) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();

    final data = {
      'name': name,
      'price': price,
      'stock': stock,
      'category': category,
      'updated_at': now,
    };

    final count = await db.update(
      'products',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );

    return count > 0;
  }

  // Delete: Soft Delete produk (mengisi kolom deleted_at) agar riwayat transaksi masa lalu tidak rusak
  Future<bool> deleteProduct(int id) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();

    final count = await db.update(
      'products',
      {'deleted_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );

    return count > 0;
  }

  // =========================================================================
  // LOGIK TRANSAKSI KASIR (CHECKOUT & POTONG STOK)
  // =========================================================================

  // Checkout: Menyimpan transaksi ke SQLite dengan proteksi ACID Transaction
  Future<String?> checkout(List<CartItem> items, int totalAmount) async {
    final db = await instance.database;
    final now = DateTime.now();
    final nowString = now.toIso8601String();

    String? generatedInvoice;

    // Membuka database transaction lokal untuk memastikan keamanan data
    await db.transaction((txn) async {
      // 1. Generate Nomor Invoice (Format: INV-YYYYMMDD-XXXX)
      final dateSlug = DateFormat('yyyyMMdd').format(now);

      final todayTransactions = await txn.rawQuery(
        '''
        SELECT COUNT(*) as total FROM transactions 
        WHERE invoice_no LIKE ?
      ''',
        ['INV-$dateSlug-%'],
      );

      int currentCount = todayTransactions.first['total'] as int? ?? 0;
      final sequence = (currentCount + 1).toString().padLeft(4, '0');
      generatedInvoice = 'INV-$dateSlug-$sequence';

      // 2. Insert ke tabel induk 'transactions'
      final transactionId = await txn.insert('transactions', {
        'invoice_no': generatedInvoice,
        'total_amount': totalAmount,
        'transaction_date': nowString,
        'created_at': nowString,
        'updated_at': nowString,
      });

      // 3. Loop item keranjang belanja untuk disimpan dan potong stok
      for (var item in items) {
        // Simpan detail item transaksi
        await txn.insert('transaction_details', {
          'transaction_id': transactionId,
          'product_id': item.product.id,
          'qty': item.qty,
          'subtotal': item.subtotal,
          'created_at': nowString,
          'updated_at': nowString,
        });

        // Eksekusi potong stok di database lokal
        await txn.rawUpdate(
          '''
          UPDATE products 
          SET stock = stock - ?, updated_at = ? 
          WHERE id = ?
        ''',
          [item.qty, nowString, item.product.id],
        );
      }
    });

    return generatedInvoice; // Mengembalikan nomor invoice sukses
  }

  // =========================================================================
  // LOGIK RIWAYAT PENJUALAN (HISTORY)
  // =========================================================================

  Future<List<TransactionModel>> getTransactionHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await instance.database;
    List<Map<String, dynamic>> txnResult;

    if (startDate != null && endDate != null) {
      // Konversi format ke tanggal murni (start 00:00:00, end 23:59:59)
      final startStr = "${DateFormat('yyyy-MM-dd').format(startDate)}T00:00:00";
      final endStr = "${DateFormat('yyyy-MM-dd').format(endDate)}T23:59:59";

      txnResult = await db.query(
        'transactions',
        where: 'transaction_date >= ? AND transaction_date <= ?',
        whereArgs: [startStr, endStr],
        orderBy: 'transaction_date DESC',
      );
    } else {
      // Default: Ambil maksimal 50 transaksi terakhir jika tanpa filter
      txnResult = await db.query(
        'transactions',
        orderBy: 'transaction_date DESC',
        limit: 50,
      );
    }

    List<TransactionModel> formattedList = [];

    // Lakukan mapping relasi detail item untuk dimasukkan ke dalam objek model
    for (var txn in txnResult) {
      final details = await db.rawQuery(
        '''
        SELECT td.*, p.name as product_name 
        FROM transaction_details td
        LEFT JOIN products p ON td.product_id = p.id
        WHERE td.transaction_id = ?
      ''',
        [txn['id']],
      );

      // Susun item detail agar lolos parsing `TransactionItemModel.fromJson`
      final formattedItems = details.map((detail) {
        return {
          'product_id': detail['product_id'],
          'product_name': detail['product_name'] ?? 'Produk Terhapus',
          'price': (detail['subtotal'] as int) ~/ (detail['qty'] as int),
          'qty': detail['qty'],
          'subtotal': detail['subtotal'],
        };
      }).toList();

      // Bungkus data mentah agar presisi dengan model `TransactionModel.fromJson`
      final rawTransaction = {
        'id': txn['id'],
        'transaction_id': txn['id'].toString(), // Inject key untuk model Anda
        'invoice_number': txn['invoice_no'], // Map ke key model Anda
        'total_amount': txn['total_amount'],
        'created_at': _formatDisplayDate(txn['transaction_date'].toString()),
        'items': formattedItems,
      };

      formattedList.add(TransactionModel.fromJson(rawTransaction));
    }

    return formattedList;
  }

  // Helper untuk mengubah tanggal database ISO8601 ke pola tampilan UI lama ('d-m-Y H:i')
  String _formatDisplayDate(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return DateFormat('dd-MM-yyyy HH:mm').format(dateTime);
    } catch (_) {
      return isoString;
    }
  }
}
