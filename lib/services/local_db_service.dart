import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import '../models/product_model.dart';
import '../models/transaction_model.dart';
import '../models/cart_item_model.dart';
import '../models/sales_analytics_model.dart';
import 'sales_insight_engine.dart';

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
      version: 3, // [TAMBAHAN]: Naik versi ke 3 untuk migrasi otomatis
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  /// Membuat tabel database
  Future _createDB(Database db, int version) async {
    if (version == 1) {
      await _createDBv1(db);
      await _upgradeDBv2(db);
      await _upgradeDBv3(db); // [TAMBAHAN]
    } else if (version == 2) {
      await _createDBv2(db);
      await _upgradeDBv3(db); // [TAMBAHAN]
    } else if (version >= 3) {
      await _createDBv2(db);
      await _createDBv3(db); // [TAMBAHAN]
    }
  }

  Future _createDBv1(Database db) async {
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

  // [TAMBAHAN]: Membuat tabel pengaturan struk
  Future _createDBv3(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS receipt_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        store_name TEXT NOT NULL,
        store_address TEXT NOT NULL,
        store_contact TEXT NOT NULL,
        footer_message TEXT NOT NULL,
        paper_size INTEGER NOT NULL
      )
    ''');

    // Masukkan data bawaan (default)
    await db.insert('receipt_settings', {
      'store_name': 'NANDA CELL',
      'store_address': 'Pusat Accessories & Service HP',
      'store_contact': 'WhatsApp: 08xx-xxxx-xxxx',
      'footer_message': 'Terima Kasih Atas Kunjungan Anda',
      'paper_size': 58,
    });
  }

  Future<void> _upgradeDBv2(Database db) async {
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

  // [TAMBAHAN] Upgrade database ke v3
  Future<void> _upgradeDBv3(Database db) async {
    await _createDBv3(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _upgradeDBv2(db);
    }
    if (oldVersion < 3) {
      await _upgradeDBv3(db); // [TAMBAHAN] Eksekusi migrasi v3
    }
  }

  // =========================================================================
  // [TAMBAHAN] PENGATURAN STRUK (RECEIPT SETTINGS)
  // =========================================================================

  Future<Map<String, dynamic>> getReceiptSettings() async {
    final db = await instance.database;
    final result = await db.query('receipt_settings', limit: 1);
    if (result.isNotEmpty) {
      return result.first;
    }
    // Fallback darurat
    return {
      'store_name': 'NANDA CELL',
      'store_address': 'Pusat Accessories & Service HP',
      'store_contact': 'WhatsApp: 08xx-xxxx-xxxx',
      'footer_message': 'Terima Kasih Atas Kunjungan Anda',
      'paper_size': 58,
    };
  }

  Future<bool> updateReceiptSettings(
    String name,
    String address,
    String contact,
    String footer,
    int paperSize,
  ) async {
    final db = await instance.database;
    final data = {
      'store_name': name,
      'store_address': address,
      'store_contact': contact,
      'footer_message': footer,
      'paper_size': paperSize,
    };

    final count = await db.query('receipt_settings');
    if (count.isEmpty) {
      await db.insert('receipt_settings', data);
      return true;
    } else {
      final updated = await db.update(
        'receipt_settings',
        data,
        where: 'id = ?',
        whereArgs: [count.first['id']],
      );
      return updated > 0;
    }
  }

  // =========================================================================
  // LOGIK MANAJEMEN PRODUK (CRUD HARD DELETE)
  // =========================================================================

  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    final result = await db.query('products', orderBy: 'name ASC');
    return result.map((json) => Product.fromJson(json)).toList();
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      "SELECT * FROM products WHERE name LIKE ? OR code LIKE ?",
      ['%$query%', '%$query%'],
    );
    return result.map((json) => Product.fromJson(json)).toList();
  }

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
  // LOGIK ANALISIS PENJUALAN
  // =========================================================================

  static const List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  static const List<String> _monthShortNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  Future<List<int>> getAvailableTransactionYears() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT DISTINCT substr(transaction_date, 1, 4) as yr 
      FROM transactions 
      WHERE transaction_date IS NOT NULL AND length(transaction_date) >= 4
      ORDER BY yr DESC
    ''');

    final years = <int>{DateTime.now().year};
    for (var row in result) {
      final yrStr = row['yr'] as String?;
      if (yrStr != null) {
        final yrInt = int.tryParse(yrStr);
        if (yrInt != null && yrInt > 2000 && yrInt < 2100) {
          years.add(yrInt);
        }
      }
    }
    final list = years.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  Future<SalesAnalyticsSummary> getYearlyAnalytics(int year) async {
    final db = await instance.database;
    final startStr = '$year-01-01';
    final endStr = '${year + 1}-01-01';

    final result = await db.rawQuery('''
      SELECT 
        CAST(substr(transaction_date, 6, 2) AS INTEGER) as month_num,
        COALESCE(SUM(total_amount), 0) as total_amount,
        COUNT(*) as transaction_count
      FROM transactions
      WHERE transaction_date >= ? AND transaction_date < ?
      GROUP BY month_num
    ''', [startStr, endStr]);

    final map = <int, Map<String, dynamic>>{};
    for (var row in result) {
      final mo = row['month_num'] as int;
      map[mo] = row;
    }

    final dataPoints = <SalesAnalyticsDataPoint>[];
    for (int m = 1; m <= 12; m++) {
      final row = map[m];
      final total = (row?['total_amount'] as int?) ?? 0;
      final count = (row?['transaction_count'] as int?) ?? 0;
      final mStr = m.toString().padLeft(2, '0');

      dataPoints.add(SalesAnalyticsDataPoint(
        label: _monthShortNames[m - 1],
        fullLabel: '${_monthNames[m - 1]} $year',
        totalAmount: total,
        transactionCount: count,
        dateKey: '$year-$mStr',
      ));
    }

    final topProducts = await getTopSellingProducts(
      startDate: DateTime(year, 1, 1),
      endDate: DateTime(year + 1, 1, 1),
    );

    return _buildSummary(
      scale: AnalyticsScale.yearly,
      periodTitle: 'Tahun $year (12 Bulan)',
      dataPoints: dataPoints,
      topProducts: topProducts,
    );
  }

  Future<SalesAnalyticsSummary> getMonthlyDailyAnalytics(int year, int month) async {
    final db = await instance.database;
    final mStr = month.toString().padLeft(2, '0');
    final startStr = '$year-$mStr-01';
    final nextMonth = month == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    final endStr = '${nextMonth.year}-${nextMonth.month.toString().padLeft(2, '0')}-01';

    final result = await db.rawQuery('''
      SELECT 
        CAST(substr(transaction_date, 9, 2) AS INTEGER) as day_num,
        COALESCE(SUM(total_amount), 0) as total_amount,
        COUNT(*) as transaction_count
      FROM transactions
      WHERE transaction_date >= ? AND transaction_date < ?
      GROUP BY day_num
    ''', [startStr, endStr]);

    final map = <int, Map<String, dynamic>>{};
    for (var row in result) {
      final day = row['day_num'] as int;
      map[day] = row;
    }

    final daysInMonth = DateTime(year, month + 1, 0).day;
    final dataPoints = <SalesAnalyticsDataPoint>[];

    for (int d = 1; d <= daysInMonth; d++) {
      final row = map[d];
      final total = (row?['total_amount'] as int?) ?? 0;
      final count = (row?['transaction_count'] as int?) ?? 0;
      final dStr = d.toString().padLeft(2, '0');

      dataPoints.add(SalesAnalyticsDataPoint(
        label: d.toString(),
        fullLabel: '$d ${_monthNames[month - 1]} $year',
        totalAmount: total,
        transactionCount: count,
        dateKey: '$year-$mStr-$dStr',
      ));
    }

    final topProducts = await getTopSellingProducts(
      startDate: DateTime(year, month, 1),
      endDate: nextMonth,
    );

    return _buildSummary(
      scale: AnalyticsScale.monthly,
      periodTitle: '${_monthNames[month - 1]} $year',
      dataPoints: dataPoints,
      topProducts: topProducts,
    );
  }

  Future<SalesAnalyticsSummary> getMonthRangeAnalytics(
    int year,
    int startMonth,
    int endMonth,
  ) async {
    final db = await instance.database;
    int fromM = startMonth;
    int toM = endMonth;
    if (fromM > toM) {
      final tmp = fromM;
      fromM = toM;
      toM = tmp;
    }

    final startStr = '$year-${fromM.toString().padLeft(2, '0')}-01';
    final nextMonth = toM == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, toM + 1, 1);
    final endStr = '${nextMonth.year}-${nextMonth.month.toString().padLeft(2, '0')}-01';

    final result = await db.rawQuery('''
      SELECT 
        CAST(substr(transaction_date, 6, 2) AS INTEGER) as month_num,
        COALESCE(SUM(total_amount), 0) as total_amount,
        COUNT(*) as transaction_count
      FROM transactions
      WHERE transaction_date >= ? AND transaction_date < ?
      GROUP BY month_num
    ''', [startStr, endStr]);

    final map = <int, Map<String, dynamic>>{};
    for (var row in result) {
      final mo = row['month_num'] as int;
      map[mo] = row;
    }

    final dataPoints = <SalesAnalyticsDataPoint>[];
    for (int m = fromM; m <= toM; m++) {
      final row = map[m];
      final total = (row?['total_amount'] as int?) ?? 0;
      final count = (row?['transaction_count'] as int?) ?? 0;
      final mStr = m.toString().padLeft(2, '0');

      dataPoints.add(SalesAnalyticsDataPoint(
        label: _monthShortNames[m - 1],
        fullLabel: '${_monthNames[m - 1]} $year',
        totalAmount: total,
        transactionCount: count,
        dateKey: '$year-$mStr',
      ));
    }

    final topProducts = await getTopSellingProducts(
      startDate: DateTime(year, fromM, 1),
      endDate: nextMonth,
    );

    return _buildSummary(
      scale: AnalyticsScale.customRange,
      periodTitle: '${_monthNames[fromM - 1]} s/d ${_monthNames[toM - 1]} $year',
      dataPoints: dataPoints,
      topProducts: topProducts,
    );
  }

  SalesAnalyticsSummary _buildSummary({
    required AnalyticsScale scale,
    required String periodTitle,
    required List<SalesAnalyticsDataPoint> dataPoints,
    required List<Map<String, dynamic>> topProducts,
  }) {
    int totalRevenue = 0;
    int totalTransactions = 0;
    SalesAnalyticsDataPoint? highest;
    SalesAnalyticsDataPoint? lowest;

    for (var p in dataPoints) {
      totalRevenue += p.totalAmount;
      totalTransactions += p.transactionCount;

      if (highest == null || p.totalAmount > highest.totalAmount) {
        highest = p;
      }
      if (lowest == null || (p.totalAmount < lowest.totalAmount && p.totalAmount > 0)) {
        lowest = p;
      }
    }

    // Jika tidak ada data sama sekali (> 0), ambil elemen pertama
    lowest ??= dataPoints.isNotEmpty ? dataPoints.first : null;

    final double avg = dataPoints.isEmpty ? 0 : totalRevenue / dataPoints.length;

    final baseSummary = SalesAnalyticsSummary(
      scale: scale,
      periodTitle: periodTitle,
      totalRevenue: totalRevenue,
      totalTransactions: totalTransactions,
      averageRevenue: avg,
      highestPoint: highest,
      lowestPoint: lowest,
      dataPoints: dataPoints,
      topProducts: topProducts,
    );

    final insights = SalesInsightEngine.generateInsights(summary: baseSummary);

    return SalesAnalyticsSummary(
      scale: scale,
      periodTitle: periodTitle,
      totalRevenue: totalRevenue,
      totalTransactions: totalTransactions,
      averageRevenue: avg,
      highestPoint: highest,
      lowestPoint: lowest,
      dataPoints: dataPoints,
      topProducts: topProducts,
      insights: insights,
    );
  }

  // =========================================================================
  // EXPORT & IMPORT DATABASE (BACKUP .DB)
  // =========================================================================

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

  Future<void> shareDatabase() async {
    final path = await exportDatabase();
    await Share.shareXFiles([XFile(path)], text: 'Backup Database NandaCell');
  }

  Future<bool> importDatabase() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result == null || result.files.isEmpty) return false;
    final selectedFile = File(result.files.single.path!);

    if (!selectedFile.path.toLowerCase().endsWith('.db')) {
      throw Exception('Format file tidak didukung. Harap pilih file .db');
    }

    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    final dbPath = await getDatabasesPath();
    final targetPath = join(dbPath, 'nanda_cell.db');
    final targetFile = File(targetPath);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }

    await selectedFile.copy(targetPath);

    return true;
  }

  String _formatDisplayDate(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return DateFormat('dd-MM-yyyy HH:mm').format(dateTime);
    } catch (_) {
      return isoString;
    }
  }
}
