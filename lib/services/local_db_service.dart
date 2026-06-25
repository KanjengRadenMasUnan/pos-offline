import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

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

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  /// Membuat tabel database versi 1 dan upgrade ke versi 2
  Future _createDB(Database db, int version) async {
    if (version == 1) {
      await _createDBv1(db);
      await _upgradeDBv2(db);
    } else if (version >= 2) {
      await _createDBv2(db);
    }
  }

  Future _createDBv1(Database db) async {
    // Tabel produk (tidak perlu deleted_at lagi)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        price INTEGER NOT NULL,
        stock INTEGER NOT NULL,
        category TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Tabel transaksi utama
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_no TEXT NOT NULL UNIQUE,
        total_amount INTEGER NOT NULL,
        transaction_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Tabel detail transaksi dengan foreign key ke products (NO ACTION default)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transaction_details (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        product_id INTEGER,
        qty INTEGER NOT NULL,
        subtotal INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE SET NULL
      )
    ''');
  }

  Future _createDBv2(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        price INTEGER NOT NULL,
        stock INTEGER NOT NULL,
        category TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_no TEXT NOT NULL UNIQUE,
        total_amount INTEGER NOT NULL,
        transaction_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transaction_details (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        product_id INTEGER,
        qty INTEGER NOT NULL,
        subtotal INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE SET NULL
      )
    ''');
  }

  Future<void> _upgradeDBv2(Database db) async {
    // Hapus foreign key lama jika ada, lalu buat ulang tabel transaction_details dengan ON DELETE SET NULL
    await db.execute('DROP TABLE IF EXISTS transaction_details_old');
    await db.execute(
      'ALTER TABLE transaction_details RENAME TO transaction_details_old',
    );
    await _createDBv2(db);
    await db.execute('''
      INSERT INTO transaction_details (id, transaction_id, product_id, qty, subtotal, created_at, updated_at)
      SELECT id, transaction_id, product_id, qty, subtotal, created_at, updated_at FROM transaction_details_old
    ''');
    await db.execute('DROP TABLE IF EXISTS transaction_details_old');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _upgradeDBv2(db);
    }
  }

  // =========================================================================
  // LOGIK MANAJEMEN PRODUK (CRUD HARD DELETE)
  // =========================================================================

  /// Mengambil semua produk (tanpa filter deleted_at)
  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    final result = await db.query('products', orderBy: 'name ASC');
    return result.map((json) => Product.fromJson(json)).toList();
  }

  /// Cari barang berdasarkan nama atau barcode
  Future<List<Product>> searchProducts(String query) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      "SELECT * FROM products WHERE name LIKE ? OR code LIKE ?",
      ['%$query%', '%$query%'],
    );
    return result.map((json) => Product.fromJson(json)).toList();
  }

  /// Cari satu produk berdasarkan kode (untuk scanner kasir)
  Future<Product?> getProductByCode(String code) async {
    final db = await instance.database;
    final maps = await db.query(
      'products',
      where: 'code = ?',
      whereArgs: [code],
    );
    if (maps.isNotEmpty) {
      return Product.fromJson(maps.first);
    }
    return null;
  }

  /// Tambah produk baru dengan auto-generate kode BRG-XXXX jika tidak diberikan
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
      // Cari nomor tertinggi dari seluruh kode BRG-XXXX
      final lastCodeResult = await db.rawQuery(
        "SELECT MAX(CAST(SUBSTR(code, 5) AS INTEGER)) as max_num FROM products WHERE code LIKE 'BRG-%'",
      );
      int maxNum = (lastCodeResult.first['max_num'] as int?) ?? 0;
      finalCode = 'BRG-${(maxNum + 1).toString().padLeft(4, '0')}';
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

    return Product(
      id: id,
      code: finalCode,
      name: name,
      price: price,
      stock: stock,
      category: category.isEmpty ? 'Umum' : category,
    );
  }

  /// Update produk
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

  /// HAPUS PERMANEN (HARD DELETE)
  Future<bool> deleteProduct(int id) async {
    final db = await instance.database;
    final count = await db.delete('products', where: 'id = ?', whereArgs: [id]);
    return count > 0;
  }

  // =========================================================================
  // LOGIK TRANSAKSI KASIR
  // =========================================================================

  Future<String?> checkout(List<CartItem> items, int totalAmount) async {
    final db = await instance.database;
    final now = DateTime.now();
    final nowString = now.toIso8601String();

    String? generatedInvoice;

    await db.transaction((txn) async {
      final dateSlug = DateFormat('yyyyMMdd').format(now);

      final todayTransactions = await txn.rawQuery(
        "SELECT COUNT(*) as total FROM transactions WHERE invoice_no LIKE ?",
        ['INV-$dateSlug-%'],
      );

      int currentCount = todayTransactions.first['total'] as int? ?? 0;
      final sequence = (currentCount + 1).toString().padLeft(4, '0');
      generatedInvoice = 'INV-$dateSlug-$sequence';

      final transactionId = await txn.insert('transactions', {
        'invoice_no': generatedInvoice,
        'total_amount': totalAmount,
        'transaction_date': nowString,
        'created_at': nowString,
        'updated_at': nowString,
      });

      for (var item in items) {
        await txn.insert('transaction_details', {
          'transaction_id': transactionId,
          'product_id': item.product.id,
          'qty': item.qty,
          'subtotal': item.subtotal,
          'created_at': nowString,
          'updated_at': nowString,
        });

        await txn.rawUpdate(
          "UPDATE products SET stock = stock - ?, updated_at = ? WHERE id = ?",
          [item.qty, nowString, item.product.id],
        );
      }
    });

    return generatedInvoice;
  }

  // =========================================================================
  // LOGIK RIWAYAT & LAPORAN
  // =========================================================================

  Future<List<TransactionModel>> getTransactionHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await instance.database;
    List<Map<String, dynamic>> txnResult;

    if (startDate != null && endDate != null) {
      final startStr = "${DateFormat('yyyy-MM-dd').format(startDate)}T00:00:00";
      final endStr = "${DateFormat('yyyy-MM-dd').format(endDate)}T23:59:59";
      txnResult = await db.query(
        'transactions',
        where: 'transaction_date >= ? AND transaction_date <= ?',
        whereArgs: [startStr, endStr],
        orderBy: 'transaction_date DESC',
      );
    } else {
      txnResult = await db.query(
        'transactions',
        orderBy: 'transaction_date DESC',
        limit: 50,
      );
    }

    List<TransactionModel> formattedList = [];

    for (var txn in txnResult) {
      final details = await db.rawQuery(
        '''
        SELECT td.*, COALESCE(p.name, 'Produk Terhapus') as product_name 
        FROM transaction_details td
        LEFT JOIN products p ON td.product_id = p.id
        WHERE td.transaction_id = ?
        ''',
        [txn['id']],
      );

      final formattedItems = details.map((detail) {
        return {
          'product_id': detail['product_id'] ?? 0,
          'product_name': detail['product_name'],
          'price': (detail['subtotal'] as int) ~/ (detail['qty'] as int),
          'qty': detail['qty'],
          'subtotal': detail['subtotal'],
        };
      }).toList();

      final rawTransaction = {
        'id': txn['id'],
        'transaction_id': txn['id'].toString(),
        'invoice_number': txn['invoice_no'],
        'total_amount': txn['total_amount'],
        'created_at': _formatDisplayDate(txn['transaction_date'].toString()),
        'items': formattedItems,
      };

      formattedList.add(TransactionModel.fromJson(rawTransaction));
    }

    return formattedList;
  }

  // --- Query Laporan ---

  Future<int> getDailyTotalIncome(DateTime date) async {
    final db = await instance.database;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final nextDateStr = DateFormat(
      'yyyy-MM-dd',
    ).format(date.add(const Duration(days: 1)));

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total_amount), 0) as total
      FROM transactions
      WHERE transaction_date >= ? AND transaction_date < ?
      ''',
      [dateStr, nextDateStr],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> getMonthlyTotalIncome(int month, int year) async {
    final db = await instance.database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1);

    final startStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endStr = DateFormat('yyyy-MM-dd').format(endDate);

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total_amount), 0) as total
      FROM transactions
      WHERE transaction_date >= ? AND transaction_date < ?
      ''',
      [startStr, endStr],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getDailySoldItems(DateTime date) async {
    final db = await instance.database;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final nextDateStr = DateFormat(
      'yyyy-MM-dd',
    ).format(date.add(const Duration(days: 1)));

    return await db.rawQuery(
      '''
      SELECT td.product_id,
             COALESCE(p.name, 'Produk Terhapus') as product_name,
             SUM(td.qty) as total_qty,
             SUM(td.subtotal) as total_sales
      FROM transaction_details td
      JOIN transactions t ON td.transaction_id = t.id
      LEFT JOIN products p ON td.product_id = p.id
      WHERE t.transaction_date >= ? AND t.transaction_date < ?
      GROUP BY td.product_id
      ORDER BY total_qty DESC
      ''',
      [dateStr, nextDateStr],
    );
  }

  Future<List<Map<String, dynamic>>> getMonthlySoldItems(
    int month,
    int year,
  ) async {
    final db = await instance.database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1);
    final startStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endStr = DateFormat('yyyy-MM-dd').format(endDate);

    return await db.rawQuery(
      '''
      SELECT td.product_id,
             COALESCE(p.name, 'Produk Terhapus') as product_name,
             SUM(td.qty) as total_qty,
             SUM(td.subtotal) as total_sales
      FROM transaction_details td
      JOIN transactions t ON td.transaction_id = t.id
      LEFT JOIN products p ON td.product_id = p.id
      WHERE t.transaction_date >= ? AND t.transaction_date < ?
      GROUP BY td.product_id
      ORDER BY total_qty DESC
      ''',
      [startStr, endStr],
    );
  }

  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await instance.database;
    final startStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endStr = DateFormat('yyyy-MM-dd').format(endDate);

    return await db.rawQuery(
      '''
      SELECT td.product_id,
             COALESCE(p.name, 'Produk Terhapus') as product_name,
             SUM(td.qty) as total_qty
      FROM transaction_details td
      JOIN transactions t ON td.transaction_id = t.id
      LEFT JOIN products p ON td.product_id = p.id
      WHERE t.transaction_date >= ? AND t.transaction_date < ?
      GROUP BY td.product_id
      ORDER BY total_qty DESC
      LIMIT 10
      ''',
      [startStr, endStr],
    );
  }

  Future<List<Map<String, dynamic>>> getLowStockProducts() async {
    final db = await instance.database;
    return await db.rawQuery(
      'SELECT id, code, name, stock FROM products WHERE stock > 0 AND stock <= 5 ORDER BY stock ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getOutOfStockProducts() async {
    final db = await instance.database;
    return await db.rawQuery(
      'SELECT id, code, name, stock FROM products WHERE stock = 0 ORDER BY name ASC',
    );
  }

  // =========================================================================
  // EXPORT & IMPORT DATABASE (BACKUP .DB)
  // =========================================================================

  /// Menyalin file database ke folder sementara dan mengembalikan path-nya
  Future<String> exportDatabase() async {
    final dbPath = await getDatabasesPath();
    final original = join(dbPath, 'nanda_cell.db');

    final tempDir = await getTemporaryDirectory();
    final backupFile = File(
      '${tempDir.path}/nanda_backup_${DateTime.now().millisecondsSinceEpoch}.db',
    );

    await File(original).copy(backupFile.path);
    return backupFile.path;
  }

  /// Membagikan file database langsung ke aplikasi lain
  Future<void> shareDatabase() async {
    final path = await exportDatabase();
    await Share.shareXFiles([XFile(path)], text: 'Backup Database NandaCell');
  }

  /// Mengimpor file .db baru: pilih file, timpa database lama, lalu reset koneksi
  Future<bool> importDatabase() async {
    // 1. Pilih file .db dari penyimpanan
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result == null || result.files.isEmpty) return false;
    final selectedFile = File(result.files.single.path!);

    // 2. Validasi ekstensi (opsional)
    if (!selectedFile.path.toLowerCase().endsWith('.db')) {
      throw Exception('Format file tidak didukung. Harap pilih file .db');
    }

    // 3. Tutup database yang sedang berjalan
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // 4. Hapus database lama
    final dbPath = await getDatabasesPath();
    final targetPath = join(dbPath, 'nanda_cell.db');
    final targetFile = File(targetPath);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }

    // 5. Salin file baru ke lokasi database
    await selectedFile.copy(targetPath);

    return true;
  }

  // Helper untuk mengubah tanggal database ISO8601 ke pola tampilan UI lama
  String _formatDisplayDate(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return DateFormat('dd-MM-yyyy HH:mm').format(dateTime);
    } catch (_) {
      return isoString;
    }
  }
}
