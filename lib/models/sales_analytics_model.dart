import '../services/sales_insight_engine.dart';

enum AnalyticsScale {
  yearly, // 1 tahun penuh (12 bulan)
  monthly, // 1 bulan penuh (harian tgl 1 - akhir bulan)
  customRange, // periode rentang bulan tertentu (misal: Maret - Agustus)
}

class SalesAnalyticsDataPoint {
  final String label; // Label pendek untuk sumbu X (misal: "Jan", "Tgl 1")
  final String fullLabel; // Label lengkap untuk tooltip & tabel (misal: "Januari 2025")
  final int totalAmount; // Total penjualan (rupiah)
  final int transactionCount; // Jumlah transaksi
  final String dateKey; // Key identifikasi (misal: "2025-01")

  SalesAnalyticsDataPoint({
    required this.label,
    required this.fullLabel,
    required this.totalAmount,
    required this.transactionCount,
    required this.dateKey,
  });
}

class SalesAnalyticsSummary {
  final AnalyticsScale scale;
  final String periodTitle;
  final int totalRevenue;
  final int totalTransactions;
  final double averageRevenue;
  final SalesAnalyticsDataPoint? highestPoint;
  final SalesAnalyticsDataPoint? lowestPoint;
  final List<SalesAnalyticsDataPoint> dataPoints;
  final List<Map<String, dynamic>> topProducts;
  final SalesInsightsResult? insights;

  SalesAnalyticsSummary({
    required this.scale,
    required this.periodTitle,
    required this.totalRevenue,
    required this.totalTransactions,
    required this.averageRevenue,
    this.highestPoint,
    this.lowestPoint,
    required this.dataPoints,
    this.topProducts = const [],
    this.insights,
  });
}
