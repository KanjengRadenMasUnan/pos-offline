import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/sales_analytics_model.dart';
import '../../../utils/currency_format.dart';
import '../../../config/app_theme.dart';

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
      return SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'Tidak ada data transaksi untuk ditampilkan pada grafik.',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textMuted,
              fontSize: 12.5,
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
          height: 280,
          child: chart,
        ),
      );
    }

    return SizedBox(
      height: 280,
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
            getTooltipColor: (_) => AppTheme.primaryDark,
            tooltipBorderRadius: BorderRadius.circular(6),
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final point = points[group.x.toInt()];
              return BarTooltipItem(
                '${point.fullLabel}\n',
                GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
                children: [
                  TextSpan(
                    text: '${CurrencyFormat.convertToIdr(point.totalAmount, 0)}\n',
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  TextSpan(
                    text: '${point.transactionCount} Transaksi',
                    style: GoogleFonts.jetBrainsMono(
                      color: AppTheme.slateGraphite,
                      fontSize: 10,
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
              reservedSize: 48,
              getTitlesWidget: (val, meta) {
                if (val == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    _formatCompact(val),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
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
              reservedSize: 26,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    points[idx].label,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: isDaily ? 9.5 : 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
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
            color: AppTheme.cardBorderColor,
            strokeWidth: 1,
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
                color: isHighest
                    ? AppTheme.primaryDark
                    : AppTheme.leadAsphalt,
                width: isDaily ? 14 : 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: AppTheme.surfaceRecessed,
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
            getTooltipColor: (_) => AppTheme.primaryDark,
            tooltipBorderRadius: BorderRadius.circular(6),
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            tooltipMargin: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                final p = points[idx];
                return LineTooltipItem(
                  '${p.fullLabel}\n',
                  GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                  children: [
                    TextSpan(
                      text: '${CurrencyFormat.convertToIdr(p.totalAmount, 0)}\n',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    TextSpan(
                      text: '${p.transactionCount} Transaksi',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppTheme.slateGraphite,
                        fontSize: 10,
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
              reservedSize: 48,
              getTitlesWidget: (val, meta) {
                if (val == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    _formatCompact(val),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
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
              reservedSize: 26,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    points[idx].label,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: isDaily ? 9.5 : 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
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
            color: AppTheme.cardBorderColor,
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            barWidth: 2,
            color: AppTheme.primaryDark,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final p = points[index];
                final isHighest = summary.highestPoint != null &&
                    summary.highestPoint!.dateKey == p.dateKey &&
                    p.totalAmount > 0;

                return FlDotCirclePainter(
                  radius: isHighest ? 4.5 : 3.0,
                  color: isHighest ? AppTheme.stampRed : Colors.white,
                  strokeWidth: 1.5,
                  strokeColor: isHighest ? AppTheme.stampRed : AppTheme.primaryDark,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primaryDark.withValues(alpha: 0.05),
            ),
          ),
        ],
      ),
    );
  }
}
