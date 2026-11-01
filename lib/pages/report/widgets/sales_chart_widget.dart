import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../models/sales_analytics_model.dart';
import '../../../utils/currency_format.dart';

class SalesChartWidget extends StatelessWidget {
  final SalesAnalyticsSummary summary;
  final String chartType; // 'bar' | 'line'

  const SalesChartWidget({
    super.key,
    required this.summary,
    required this.chartType,
  });

  String _formatCompact(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}M';
    } else if (value >= 1000000) {
      final inM = value / 1000000;
      return inM >= 10 ? '${inM.toStringAsFixed(0)}jt' : '${inM.toStringAsFixed(1)}jt';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}rb';
    }
    return value.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final points = summary.dataPoints;
    if (points.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'Tidak ada data untuk ditampilkan pada grafik.',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    double maxVal = 0;
    for (var p in points) {
      if (p.totalAmount > maxVal) maxVal = p.totalAmount.toDouble();
    }
    final chartMaxY = maxVal == 0 ? 100000.0 : maxVal * 1.18;

    final isDaily = summary.scale == AnalyticsScale.monthly;
    final itemWidth = isDaily ? 36.0 : 48.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final neededWidth = max(screenWidth - 64, points.length * itemWidth);
    final needScroll = isDaily && points.length > 14;

    final Widget chart = chartType == 'line'
        ? _buildLineChart(points, chartMaxY, isDaily)
        : _buildBarChart(points, chartMaxY, isDaily);

    if (needScroll) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          width: neededWidth,
          height: 290,
          child: chart,
        ),
      );
    }

    return SizedBox(
      height: 290,
      child: chart,
    );
  }

  Widget _buildBarChart(
    List<SalesAnalyticsDataPoint> points,
    double maxY,
    bool isDaily,
  ) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF0F172A),
            tooltipBorderRadius: BorderRadius.circular(10),
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final point = points[group.x.toInt()];
              return BarTooltipItem(
                '${point.fullLabel}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: -0.2,
                ),
                children: [
                  TextSpan(
                    text: '${CurrencyFormat.convertToIdr(point.totalAmount, 0)}\n',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: -0.3,
                    ),
                  ),
                  TextSpan(
                    text: '${point.transactionCount} Transaksi',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 46,
              getTitlesWidget: (val, meta) {
                if (val == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    _formatCompact(val),
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    points[idx].label,
                    style: TextStyle(
                      fontSize: isDaily ? 10 : 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? (maxY / 4) : 1,
          getDrawingHorizontalLine: (val) => FlLine(
            color: const Color(0xFFF1F5F9),
            strokeWidth: 1.2,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(points.length, (idx) {
          final p = points[idx];
          final isHighest = summary.highestPoint != null &&
              summary.highestPoint!.dateKey == p.dateKey &&
              p.totalAmount > 0;

          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: p.totalAmount.toDouble(),
                gradient: LinearGradient(
                  colors: isHighest
                      ? [const Color(0xFFD97706), const Color(0xFFF59E0B)]
                      : [const Color(0xFF1D4ED8), const Color(0xFF3B82F6)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: isDaily ? 14 : 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: const Color(0xFFF8FAFC),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLineChart(
    List<SalesAnalyticsDataPoint> points,
    double maxY,
    bool isDaily,
  ) {
    final spots = List.generate(
      points.length,
      (idx) => FlSpot(idx.toDouble(), points[idx].totalAmount.toDouble()),
    );

    return LineChart(
      LineChartData(
        maxY: maxY,
        minY: 0,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF0F172A),
            tooltipBorderRadius: BorderRadius.circular(10),
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            tooltipMargin: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                final p = points[idx];
                return LineTooltipItem(
                  '${p.fullLabel}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: -0.2,
                  ),
                  children: [
                    TextSpan(
                      text: '${CurrencyFormat.convertToIdr(p.totalAmount, 0)}\n',
                      style: const TextStyle(
                        color: Color(0xFF2DD4BF),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: -0.3,
                      ),
                    ),
                    TextSpan(
                      text: '${p.transactionCount} Transaksi',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 46,
              getTitlesWidget: (val, meta) {
                if (val == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    _formatCompact(val),
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    points[idx].label,
                    style: TextStyle(
                      fontSize: isDaily ? 10 : 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? (maxY / 4) : 1,
          getDrawingHorizontalLine: (val) => FlLine(
            color: const Color(0xFFF1F5F9),
            strokeWidth: 1.2,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            barWidth: 3.0,
            color: const Color(0xFF0D9488),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final p = points[index];
                final isHighest = summary.highestPoint != null &&
                    summary.highestPoint!.dateKey == p.dateKey &&
                    p.totalAmount > 0;

                return FlDotCirclePainter(
                  radius: isHighest ? 5.5 : 3.5,
                  color: isHighest ? const Color(0xFFF59E0B) : Colors.white,
                  strokeWidth: 2.2,
                  strokeColor: isHighest ? Colors.white : const Color(0xFF0D9488),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0D9488).withValues(alpha: 0.20),
                  const Color(0xFF0D9488).withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
