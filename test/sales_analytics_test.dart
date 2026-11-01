import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartcampus/models/sales_analytics_model.dart';
import 'package:smartcampus/services/sales_insight_engine.dart';
import 'package:smartcampus/services/sales_analytics_export_service.dart';
import 'package:smartcampus/services/sales_chart_image_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock path_provider method channel
  const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    return Directory.systemTemp.path;
  });

  group('Sales Analytics Model & Calculations', () {
    test('SalesAnalyticsSummary correctly summarizes points and peaks', () {
      final points = [
        SalesAnalyticsDataPoint(
          label: 'Jan',
          fullLabel: 'Januari 2025',
          totalAmount: 10000000,
          transactionCount: 20,
          dateKey: '2025-01',
        ),
        SalesAnalyticsDataPoint(
          label: 'Feb',
          fullLabel: 'Februari 2025',
          totalAmount: 25000000,
          transactionCount: 45,
          dateKey: '2025-02',
        ),
        SalesAnalyticsDataPoint(
          label: 'Mar',
          fullLabel: 'Maret 2025',
          totalAmount: 15000000,
          transactionCount: 30,
          dateKey: '2025-03',
        ),
      ];

      final summary = SalesAnalyticsSummary(
        scale: AnalyticsScale.yearly,
        periodTitle: 'Tahun 2025 (12 Bulan)',
        totalRevenue: 50000000,
        totalTransactions: 95,
        averageRevenue: 50000000 / 3,
        highestPoint: points[1],
        lowestPoint: points[0],
        dataPoints: points,
      );

      expect(summary.totalRevenue, 50000000);
      expect(summary.totalTransactions, 95);
      expect(summary.highestPoint?.totalAmount, 25000000);
      expect(summary.highestPoint?.label, 'Feb');
      expect(summary.lowestPoint?.totalAmount, 10000000);
      expect(summary.dataPoints.length, 3);
    });

    test('SalesInsightEngine generates concise statistical insights', () {
      final points = [
        SalesAnalyticsDataPoint(
          label: 'Jan',
          fullLabel: 'Januari 2025',
          totalAmount: 10000000,
          transactionCount: 20,
          dateKey: '2025-01',
        ),
        SalesAnalyticsDataPoint(
          label: 'Feb',
          fullLabel: 'Februari 2025',
          totalAmount: 20000000,
          transactionCount: 40,
          dateKey: '2025-02',
        ),
        SalesAnalyticsDataPoint(
          label: 'Mar',
          fullLabel: 'Maret 2025',
          totalAmount: 30000000,
          transactionCount: 60,
          dateKey: '2025-03',
        ),
      ];

      final summary = SalesAnalyticsSummary(
        scale: AnalyticsScale.yearly,
        periodTitle: 'Tahun 2025',
        totalRevenue: 60000000,
        totalTransactions: 120,
        averageRevenue: 20000000,
        highestPoint: points[2],
        lowestPoint: points[0],
        dataPoints: points,
        topProducts: [
          {'product_name': 'Kabel Data Type C', 'total_qty': 50}
        ],
      );

      final insights = SalesInsightEngine.generateInsights(summary: summary);

      // Verifikasi AOV: 60,000,000 / 120 = 500,000
      expect(insights.averageOrderValue, 500000);
      expect(insights.growthRatePercent, 200.0);
      expect(insights.trendStatus.contains('Pertumbuhan') || insights.trendStatus.contains('Meningkat'), isTrue);
      expect(insights.peakPoint?.label, 'Mar');
      expect(insights.keyFindings.isNotEmpty, isTrue);
      expect(insights.strategicRecommendations.isNotEmpty, isTrue);
      expect(insights.executiveSummary.contains('Tahun 2025'), isTrue);
    });

    test('SalesAnalyticsExportService exports PDF, Excel, and PPTX successfully', () async {
      final points = [
        SalesAnalyticsDataPoint(
          label: 'Jan',
          fullLabel: 'Januari 2025',
          totalAmount: 10000000,
          transactionCount: 20,
          dateKey: '2025-01',
        ),
        SalesAnalyticsDataPoint(
          label: 'Feb',
          fullLabel: 'Februari 2025',
          totalAmount: 25000000,
          transactionCount: 45,
          dateKey: '2025-02',
        ),
      ];

      final summary = SalesAnalyticsSummary(
        scale: AnalyticsScale.yearly,
        periodTitle: 'Tahun 2025 (12 Bulan)',
        totalRevenue: 35000000,
        totalTransactions: 65,
        averageRevenue: 17500000,
        highestPoint: points[1],
        lowestPoint: points[0],
        dataPoints: points,
        topProducts: [
          {'product_name': 'Tempered Glass', 'total_qty': 30}
        ],
      );

      final exportService = SalesAnalyticsExportService.instance;

      // 0. Test Chart Image Renderer
      final barBytes = SalesChartImageRenderer.renderBarChart(summary);
      expect(barBytes.isNotEmpty, isTrue);
      final lineBytes = SalesChartImageRenderer.renderLineChart(summary);
      expect(lineBytes.isNotEmpty, isTrue);

      // 1. Test PDF
      final pdfFile = await exportService.exportToPdf(summary);
      expect(await pdfFile.exists(), isTrue);
      expect(await pdfFile.length(), greaterThan(0));

      // 2. Test Excel
      final excelFile = await exportService.exportToExcel(summary);
      expect(await excelFile.exists(), isTrue);
      expect(await excelFile.length(), greaterThan(0));

      // 3. Test PowerPoint
      final pptxFile = await exportService.exportToPptx(summary);
      expect(await pptxFile.exists(), isTrue);
      expect(await pptxFile.length(), greaterThan(0));
    });
  });
}
