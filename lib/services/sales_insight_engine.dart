import 'dart:math';
import '../models/sales_analytics_model.dart';
import '../utils/currency_format.dart';

class InsightFinding {
  final String title;
  final String description;
  final String type; // 'positive' | 'warning' | 'neutral' | 'highlight'

  InsightFinding({
    required this.title,
    required this.description,
    required this.type,
  });
}

class SalesInsightsResult {
  final String executiveSummary;
  final String trendStatus; // e.g. "Pertumbuhan Kuat", "Tren Menurun", "Stabil Konsisten"
  final double growthRatePercent; // Perubahan dari awal ke akhir periode
  final double coefficientOfVariation; // Volatilitas (%)
  final String stabilityLevel; // Sangat Stabil, Cukup Stabil, Fluktuatif, Volatil
  final int averageOrderValue; // Rata-rata belanja per struk (AOV)
  final SalesAnalyticsDataPoint? peakPoint;
  final double peakAboveAveragePercent;
  final SalesAnalyticsDataPoint? troughPoint;
  final double troughBelowAveragePercent;
  final List<InsightFinding> keyFindings;
  final List<String> strategicRecommendations;

  SalesInsightsResult({
    required this.executiveSummary,
    required this.trendStatus,
    required this.growthRatePercent,
    required this.coefficientOfVariation,
    required this.stabilityLevel,
    required this.averageOrderValue,
    this.peakPoint,
    required this.peakAboveAveragePercent,
    this.troughPoint,
    required this.troughBelowAveragePercent,
    required this.keyFindings,
    required this.strategicRecommendations,
  });
}

class SalesInsightEngine {
  /// Algoritma komputasi data analitik penjualan yang menghasilkan insight
  /// statistik singkat, padat, presisi, dan mudah dipahami.
  static SalesInsightsResult generateInsights({
    required SalesAnalyticsSummary summary,
  }) {
    final points = summary.dataPoints;
    final totalRevenue = summary.totalRevenue;
    final totalTx = summary.totalTransactions;

    if (points.isEmpty || totalRevenue == 0) {
      return SalesInsightsResult(
        executiveSummary:
            'Belum ada transaksi penjualan yang tercatat pada ${summary.periodTitle}.',
        trendStatus: 'Tidak Ada Data',
        growthRatePercent: 0,
        coefficientOfVariation: 0,
        stabilityLevel: 'Nihil Aktivitas',
        averageOrderValue: 0,
        peakAboveAveragePercent: 0,
        troughBelowAveragePercent: 0,
        keyFindings: [
          InsightFinding(
            title: 'Nihil Transaksi',
            description: 'Tidak ada data penjualan pada periode ini.',
            type: 'neutral',
          ),
        ],
        strategicRecommendations: [
          'Pastikan kasir selalu mencatat transaksi harian pada aplikasi POS.',
        ],
      );
    }

    final n = points.length;
    final double meanRevenue = totalRevenue / n;

    // 1. REGRESI LINIER / SLOPE ARAH TREN (Least Squares)
    double sumX = 0;
    double sumY = 0;
    double sumXY = 0;
    double sumX2 = 0;

    for (int i = 0; i < n; i++) {
      final x = i.toDouble();
      final y = points[i].totalAmount.toDouble();
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    double slope = 0;
    final denominator = (n * sumX2 - sumX * sumX);
    if (denominator != 0) {
      slope = (n * sumXY - sumX * sumY) / denominator;
    }

    final firstPointRevenue = points.first.totalAmount;
    final lastPointRevenue = points.last.totalAmount;
    double overallGrowth = 0;
    if (firstPointRevenue > 0) {
      overallGrowth = ((lastPointRevenue - firstPointRevenue) / firstPointRevenue) * 100;
    } else if (lastPointRevenue > 0) {
      overallGrowth = 100;
    }

    final normalizedSlope = meanRevenue > 0 ? (slope / meanRevenue) : 0;
    String trendStatus;
    if (normalizedSlope > 0.08 || overallGrowth > 25) {
      trendStatus = 'Pertumbuhan Kuat (Uptrend)';
    } else if (normalizedSlope > 0.015 || overallGrowth > 5) {
      trendStatus = 'Meningkat Bertahap';
    } else if (normalizedSlope < -0.08 || overallGrowth < -25) {
      trendStatus = 'Penurunan (Downtrend)';
    } else if (normalizedSlope < -0.015 || overallGrowth < -5) {
      trendStatus = 'Menurun Bertahap';
    } else {
      trendStatus = 'Stabil Konsisten';
    }

    // 2. VOLATILITAS (Standar Deviasi & Koefisien Variasi)
    double sumSquaredDiff = 0;
    for (var p in points) {
      final diff = p.totalAmount - meanRevenue;
      sumSquaredDiff += diff * diff;
    }
    final variance = sumSquaredDiff / n;
    final stdDev = sqrt(variance);
    final cv = meanRevenue > 0 ? (stdDev / meanRevenue) * 100 : 0.0;

    String stabilityLevel;
    if (cv < 20) {
      stabilityLevel = 'Sangat Stabil';
    } else if (cv < 40) {
      stabilityLevel = 'Cukup Stabil';
    } else if (cv < 60) {
      stabilityLevel = 'Fluktuasi Sedang';
    } else {
      stabilityLevel = 'Fluktuatif Tinggi';
    }

    // 3. PUNCAK & LEMBAH
    final peakPoint = summary.highestPoint;
    final troughPoint = summary.lowestPoint;

    double peakAboveAvg = 0;
    if (peakPoint != null && meanRevenue > 0) {
      peakAboveAvg = ((peakPoint.totalAmount - meanRevenue) / meanRevenue) * 100;
    }

    double troughBelowAvg = 0;
    if (troughPoint != null && meanRevenue > 0) {
      troughBelowAvg = ((meanRevenue - troughPoint.totalAmount) / meanRevenue) * 100;
    }

    // 4. AVERAGE ORDER VALUE (AOV)
    final aov = totalTx > 0 ? (totalRevenue / totalTx).round() : 0;

    // 5. TEMUAN KUNCI SINGKAT & PADAT
    final findings = <InsightFinding>[];

    // Temuan Tren
    findings.add(InsightFinding(
      title: 'Arah Tren: $trendStatus',
      description: overallGrowth != 0
          ? 'Perubahan omset ${overallGrowth >= 0 ? "+" : ""}${overallGrowth.toStringAsFixed(1)}% dari awal ke akhir periode.'
          : 'Omset stabil di sepanjang periode.',
      type: normalizedSlope >= 0 ? 'positive' : 'warning',
    ));

    // Temuan Puncak
    if (peakPoint != null && peakPoint.totalAmount > 0) {
      findings.add(InsightFinding(
        title: 'Penjualan Tertinggi: ${peakPoint.label}',
        description:
            '${CurrencyFormat.convertToIdr(peakPoint.totalAmount, 0)} (${peakAboveAvg.toStringAsFixed(0)}% di atas rata-rata).',
        type: 'highlight',
      ));
    }

    // Temuan Stabilitas & Belanja
    findings.add(InsightFinding(
      title: 'Stabilitas & Nilai Transaksi',
      description:
          'Arus kas $stabilityLevel (CV ${cv.toStringAsFixed(1)}%) dengan rata-rata belanja ${CurrencyFormat.convertToIdr(aov, 0)}/struk.',
      type: 'neutral',
    ));

    // 6. REKOMENDASI TAKTIS SINGKAT
    final recommendations = <String>[];
    if (normalizedSlope < 0) {
      recommendations.add(
          'Luncurkan program promo/diskon berkala untuk mendongkrak kembali volume penjualan.');
    } else {
      recommendations.add(
          'Jaga konsistensi stok barang agar momentum pertumbuhan omset tetap terjaga.');
    }

    if (aov > 0) {
      recommendations.add(
          'Terapkan penawaran produk pelengkap (cross-selling) di kasir untuk menaikkan nilai rata-rata belanja.');
    }

    if (summary.topProducts.isNotEmpty) {
      final topName = summary.topProducts.first['product_name'] ?? 'produk unggulan';
      recommendations.add(
          'Prioritaskan ketersediaan stok "$topName" sebagai barang paling laris.');
    }

    // 7. RANGKUMAN EKSEKUTIF SINGKAT (2-3 Kalimat)
    final String peakText = peakPoint != null && peakPoint.totalAmount > 0
        ? ' Puncak omset diraih pada ${peakPoint.label} (${CurrencyFormat.convertToIdr(peakPoint.totalAmount, 0)}).'
        : '';

    final executiveSummary =
        'Total omset ${summary.periodTitle} tercatat ${CurrencyFormat.convertToIdr(totalRevenue, 0)} dari $totalTx transaksi (rata-rata ${CurrencyFormat.convertToIdr(meanRevenue, 0)} per periode). '
        'Tren penjualan berstatus $trendStatus dengan stabilitas $stabilityLevel dan rata-rata belanja ${CurrencyFormat.convertToIdr(aov, 0)} per transaksi.$peakText';

    return SalesInsightsResult(
      executiveSummary: executiveSummary,
      trendStatus: trendStatus,
      growthRatePercent: overallGrowth,
      coefficientOfVariation: cv,
      stabilityLevel: stabilityLevel,
      averageOrderValue: aov,
      peakPoint: peakPoint,
      peakAboveAveragePercent: peakAboveAvg,
      troughPoint: troughPoint,
      troughBelowAveragePercent: troughBelowAvg,
      keyFindings: findings,
      strategicRecommendations: recommendations,
    );
  }
}
