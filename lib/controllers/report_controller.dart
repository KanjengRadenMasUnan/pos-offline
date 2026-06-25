import 'package:flutter/material.dart';
import '../services/local_db_service.dart';

class ReportController extends ChangeNotifier {
  final LocalDbService _db = LocalDbService.instance;

  bool isLoading = false;
  int totalIncome = 0;
  List<Map<String, dynamic>> soldItems = [];
  List<Map<String, dynamic>> topSelling = [];
  List<Map<String, dynamic>> lowStock = [];
  List<Map<String, dynamic>> outOfStock = [];

  Future<void> loadDailyReport(DateTime date) async {
    isLoading = true;
    notifyListeners();
    try {
      final income = await _db.getDailyTotalIncome(date);
      final items = await _db.getDailySoldItems(date);
      final top = await _db.getTopSellingProducts(
        startDate: date,
        endDate: date.add(const Duration(days: 1)),
      );
      final low = await _db.getLowStockProducts();
      final out = await _db.getOutOfStockProducts();

      totalIncome = income;
      soldItems = items;
      topSelling = top;
      lowStock = low;
      outOfStock = out;
    } catch (e) {
      debugPrint('Error daily report: $e');
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadMonthlyReport(int month, int year) async {
    isLoading = true;
    notifyListeners();
    try {
      final income = await _db.getMonthlyTotalIncome(month, year);
      final items = await _db.getMonthlySoldItems(month, year);
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 1);
      final top = await _db.getTopSellingProducts(
        startDate: startDate,
        endDate: endDate,
      );
      final low = await _db.getLowStockProducts();
      final out = await _db.getOutOfStockProducts();

      totalIncome = income;
      soldItems = items;
      topSelling = top;
      lowStock = low;
      outOfStock = out;
    } catch (e) {
      debugPrint('Error monthly report: $e');
    }
    isLoading = false;
    notifyListeners();
  }
}
