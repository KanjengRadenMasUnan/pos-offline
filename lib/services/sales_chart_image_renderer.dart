import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../models/sales_analytics_model.dart';

class SalesChartImageRenderer {
  static String _formatCompact(double value) {
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

  /// Menghasilkan file PNG Diagram Batang dengan resolusi tajam
  static Uint8List renderBarChart(
    SalesAnalyticsSummary summary, {
    int width = 860,
    int height = 440,
  }) {
    final image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));

    // Border kartu luar
    img.drawRect(
      image,
      x1: 2,
      y1: 2,
      x2: width - 3,
      y2: height - 3,
      color: img.ColorRgb8(226, 232, 240),
    );

    // Header Title
    img.drawString(
      image,
      'DIAGRAM BATANG: OMSET PENJUALAN PER PERIODE',
      font: img.arial14,
      x: 30,
      y: 20,
      color: img.ColorRgb8(15, 23, 42),
    );
    img.drawString(
      image,
      summary.periodTitle,
      font: img.arial14,
      x: 30,
      y: 38,
      color: img.ColorRgb8(100, 116, 139),
    );

    // Legend
    img.fillRect(image, x1: width - 240, y1: 24, x2: width - 228, y2: 36, color: img.ColorRgb8(37, 99, 235));
    img.drawString(image, 'Omset Normal', font: img.arial14, x: width - 222, y: 22, color: img.ColorRgb8(71, 85, 105));
    img.fillRect(image, x1: width - 110, y1: 24, x2: width - 98, y2: 36, color: img.ColorRgb8(245, 158, 11));
    img.drawString(image, 'Puncak Tertinggi', font: img.arial14, x: width - 92, y: 22, color: img.ColorRgb8(71, 85, 105));

    final points = summary.dataPoints;
    if (points.isEmpty) {
      img.drawString(image, 'Tidak ada data untuk ditampilkan.', font: img.arial14, x: 50, y: 150, color: img.ColorRgb8(150, 150, 150));
      return img.encodePng(image);
    }

    double maxVal = 0;
    for (var p in points) {
      if (p.totalAmount > maxVal) maxVal = p.totalAmount.toDouble();
    }
    final maxY = maxVal == 0 ? 100000.0 : maxVal * 1.18;

    const marginLeft = 80;
    final marginRight = width - 40;
    const marginTop = 70;
    final marginBottom = height - 60;
    final plotWidth = marginRight - marginLeft;
    final plotHeight = marginBottom - marginTop;

    // Gridlines horizontal (4 baris)
    for (int i = 0; i <= 4; i++) {
      final y = marginBottom - (plotHeight * i / 4).round();
      final val = maxY * i / 4;

      img.drawLine(
        image,
        x1: marginLeft,
        y1: y,
        x2: marginRight,
        y2: y,
        color: img.ColorRgb8(241, 245, 249),
      );

      final label = _formatCompact(val);
      img.drawString(
        image,
        label,
        font: img.arial14,
        x: max(10, marginLeft - (label.length * 8) - 10),
        y: y - 7,
        color: img.ColorRgb8(148, 163, 184),
      );
    }

    // Gambar Batang
    final n = points.length;
    final slotWidth = plotWidth / n;
    final barW = max(6, min(36, (slotWidth * 0.55).round()));

    for (int i = 0; i < n; i++) {
      final p = points[i];
      final cx = marginLeft + (i * slotWidth) + (slotWidth / 2);
      final x1 = (cx - (barW / 2)).round();
      final x2 = (cx + (barW / 2)).round();

      final h = ((p.totalAmount / maxY) * plotHeight).round();
      final y1 = marginBottom - h;
      final y2 = marginBottom;

      final isHighest = summary.highestPoint != null &&
          summary.highestPoint!.dateKey == p.dateKey &&
          p.totalAmount > 0;

      // Track abu-abu di belakang
      img.fillRect(
        image,
        x1: x1,
        y1: marginTop,
        x2: x2,
        y2: y2,
        color: img.ColorRgb8(248, 250, 252),
      );

      // Batang berwarna
      if (h > 0) {
        img.fillRect(
          image,
          x1: x1,
          y1: y1,
          x2: x2,
          y2: y2,
          color: isHighest
              ? img.ColorRgb8(245, 158, 11)
              : img.ColorRgb8(37, 99, 235),
          radius: 3,
        );
      }

      // Label sumbu X
      final label = p.label;
      // Jika data harian banyak, tampilkan interval
      final shouldShowLabel = n <= 14 || i % 2 == 0 || i == n - 1;
      if (shouldShowLabel) {
        img.drawString(
          image,
          label,
          font: img.arial14,
          x: (cx - (label.length * 4)).round(),
          y: marginBottom + 12,
          color: img.ColorRgb8(71, 85, 105),
        );
      }
    }

    return img.encodePng(image);
  }

  /// Menghasilkan file PNG Diagram Garis dengan resolusi tajam
  static Uint8List renderLineChart(
    SalesAnalyticsSummary summary, {
    int width = 860,
    int height = 440,
  }) {
    final image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));

    // Border kartu luar
    img.drawRect(
      image,
      x1: 2,
      y1: 2,
      x2: width - 3,
      y2: height - 3,
      color: img.ColorRgb8(226, 232, 240),
    );

    // Header Title
    img.drawString(
      image,
      'DIAGRAM GARIS: TREN FLUKTUASI & PERTUMBUHAN',
      font: img.arial14,
      x: 30,
      y: 20,
      color: img.ColorRgb8(15, 23, 42),
    );
    img.drawString(
      image,
      summary.periodTitle,
      font: img.arial14,
      x: 30,
      y: 38,
      color: img.ColorRgb8(100, 116, 139),
    );

    final points = summary.dataPoints;
    if (points.isEmpty) {
      img.drawString(image, 'Tidak ada data untuk ditampilkan.', font: img.arial14, x: 50, y: 150, color: img.ColorRgb8(150, 150, 150));
      return img.encodePng(image);
    }

    double maxVal = 0;
    for (var p in points) {
      if (p.totalAmount > maxVal) maxVal = p.totalAmount.toDouble();
    }
    final maxY = maxVal == 0 ? 100000.0 : maxVal * 1.18;

    const marginLeft = 80;
    final marginRight = width - 40;
    const marginTop = 70;
    final marginBottom = height - 60;
    final plotWidth = marginRight - marginLeft;
    final plotHeight = marginBottom - marginTop;

    // Gridlines horizontal
    for (int i = 0; i <= 4; i++) {
      final y = marginBottom - (plotHeight * i / 4).round();
      final val = maxY * i / 4;

      img.drawLine(
        image,
        x1: marginLeft,
        y1: y,
        x2: marginRight,
        y2: y,
        color: img.ColorRgb8(241, 245, 249),
      );

      final label = _formatCompact(val);
      img.drawString(
        image,
        label,
        font: img.arial14,
        x: max(10, marginLeft - (label.length * 8) - 10),
        y: y - 7,
        color: img.ColorRgb8(148, 163, 184),
      );
    }

    final n = points.length;
    final slotWidth = plotWidth / n;
    final coords = <Point<int>>[];

    for (int i = 0; i < n; i++) {
      final p = points[i];
      final cx = (marginLeft + (i * slotWidth) + (slotWidth / 2)).round();
      final h = ((p.totalAmount / maxY) * plotHeight).round();
      final cy = marginBottom - h;
      coords.add(Point<int>(cx, cy));

      // Label sumbu X
      final label = p.label;
      final shouldShowLabel = n <= 14 || i % 2 == 0 || i == n - 1;
      if (shouldShowLabel) {
        img.drawString(
          image,
          label,
          font: img.arial14,
          x: (cx - (label.length * 4)).round(),
          y: marginBottom + 12,
          color: img.ColorRgb8(71, 85, 105),
        );
      }
    }

    // Hubungkan titik dengan garis tebal
    for (int i = 0; i < coords.length - 1; i++) {
      img.drawLine(
        image,
        x1: coords[i].x,
        y1: coords[i].y,
        x2: coords[i + 1].x,
        y2: coords[i + 1].y,
        color: img.ColorRgb8(13, 148, 136),
        thickness: 3,
        antialias: true,
      );
    }

    // Gambar titik lingkaran pada setiap koordinat
    for (int i = 0; i < coords.length; i++) {
      final p = points[i];
      final isHighest = summary.highestPoint != null &&
          summary.highestPoint!.dateKey == p.dateKey &&
          p.totalAmount > 0;

      if (isHighest) {
        img.fillCircle(
          image,
          x: coords[i].x,
          y: coords[i].y,
          radius: 7,
          color: img.ColorRgb8(245, 158, 11),
        );
      } else {
        img.fillCircle(
          image,
          x: coords[i].x,
          y: coords[i].y,
          radius: 4,
          color: img.ColorRgb8(13, 148, 136),
        );
      }
    }

    return img.encodePng(image);
  }
}

