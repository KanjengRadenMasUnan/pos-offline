import 'package:flutter/material.dart';
import '../models/sales_analytics_model.dart';
import '../services/local_db_service.dart';

class SalesAnalyticsController extends ChangeNotifier {
  final LocalDbService _db = LocalDbService.instance;

  AnalyticsScale scale = AnalyticsScale.yearly;
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  int startMonth = 1;
  int endMonth = DateTime.now().month;

  List<int> availableYears = [DateTime.now().year];
  bool isLoading = false;
  bool hasAnalyzed = false;
  SalesAnalyticsSummary? summary;
  String chartType = 'bar'; // 'bar' | 'line' | 'both'

  Future<void> init() async {
    try {
      final years = await _db.getAvailableTransactionYears();
      if (years.isNotEmpty) {
        availableYears = years;
        selectedYear = years.first;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error init available years: $e');
    }
  }

  void setScale(AnalyticsScale newScale) {
    if (scale != newScale) {
      scale = newScale;
      hasAnalyzed = false;
      notifyListeners();
    }
  }

  void setSelectedYear(int year) {
    if (selectedYear != year) {
      selectedYear = year;
      hasAnalyzed = false;
      notifyListeners();
    }
  }

  void setSelectedMonth(int month) {
    if (selectedMonth != month) {
      selectedMonth = month;
      hasAnalyzed = false;
      notifyListeners();
    }
  }

  void setMonthRange(int start, int end) {
    startMonth = start;
    endMonth = end;
    hasAnalyzed = false;
    notifyListeners();
  }

  void setChartType(String type) {
    if (chartType != type) {
      chartType = type;
      notifyListeners();
    }
  }

  Future<void> analyze() async {
    isLoading = true;
    notifyListeners();

    try {
      switch (scale) {
        case AnalyticsScale.yearly:
          summary = await _db.getYearlyAnalytics(selectedYear);
          break;
        case AnalyticsScale.monthly:
          summary = await _db.getMonthlyDailyAnalytics(selectedYear, selectedMonth);
          break;
        case AnalyticsScale.customRange:
          summary = await _db.getMonthRangeAnalytics(selectedYear, startMonth, endMonth);
          break;
      }
      hasAnalyzed = true;
    } catch (e) {
      debugPrint('Error analyzing sales: $e');
    }

    isLoading = false;
    notifyListeners();
  }
}

