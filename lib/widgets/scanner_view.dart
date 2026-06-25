import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerView extends StatefulWidget {
  final void Function(String code) onDetect;
  const ScannerView({super.key, required this.onDetect});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView>
    with SingleTickerProviderStateMixin {
  final GlobalKey _stackKey = GlobalKey();
  late final MobileScannerController _controller;
  bool _isProcessing = false;

  // Animasi overlay
  late final AnimationController _animCtrl;
  late final Animation<double> _animOpacity;

  // Ukuran area fokus (persentase layar)
  static const double _focusWidthRatio = 0.7;
  static const double _focusHeightRatio = 0.3;

  // Debounce timestamp
  DateTime _lastDetectTime = DateTime.now();

  @override
  void initState() {
    super.initState();

    // Animasi fade-in overlay
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animOpacity = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Scan Barcode"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        key: _stackKey,
        fit: StackFit.expand,
        children: [
          // Kamera
          MobileScanner(controller: _controller, onDetect: _onBarcodeDetected),

          // Overlay kotak fokus dengan animasi fade-in
          FadeTransition(
            opacity: _animOpacity,
            child: CustomPaint(
              painter: _ScannerOverlayPainter(
                focusWidthRatio: _focusWidthRatio,
                focusHeightRatio: _focusHeightRatio,
              ),
            ),
          ),

          // Petunjuk di bawah kotak
          const Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Arahkan barcode ke dalam kotak",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isProcessing) return;

    // Debounce 800ms
    final now = DateTime.now();
    if (now.difference(_lastDetectTime).inMilliseconds < 800) return;
    _lastDetectTime = now;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    // Dapatkan ukuran layar
    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final screenSize = box.size;
    final focusW = screenSize.width * _focusWidthRatio;
    final focusH = screenSize.height * _focusHeightRatio;
    final focusLeft = (screenSize.width - focusW) / 2;
    final focusTop = (screenSize.height - focusH) / 2;
    final focusRect = Rect.fromLTWH(focusLeft, focusTop, focusW, focusH);

    final sourceSize = capture.size;
    final scaleX = screenSize.width / sourceSize.width;
    final scaleY = screenSize.height / sourceSize.height;

    for (final barcode in barcodes) {
      Offset? center;

      if (barcode.corners.isNotEmpty) {
        double sumX = 0, sumY = 0;
        for (final p in barcode.corners) {
          sumX += p.dx * scaleX;
          sumY += p.dy * scaleY;
        }
        center = Offset(
          sumX / barcode.corners.length,
          sumY / barcode.corners.length,
        );
      }

      if (center == null) continue;

      // Hanya proses jika titik tengah di dalam kotak fokus
      if (focusRect.contains(center)) {
        final code = barcode.rawValue;
        if (code != null && code.isNotEmpty) {
          _isProcessing = true;
          widget.onDetect(code);
          Navigator.pop(context);
          return;
        }
      }
    }
  }
}

// ===================== PAINTER OVERLAY =====================
class _ScannerOverlayPainter extends CustomPainter {
  final double focusWidthRatio;
  final double focusHeightRatio;

  _ScannerOverlayPainter({
    required this.focusWidthRatio,
    required this.focusHeightRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final focusW = size.width * focusWidthRatio;
    final focusH = size.height * focusHeightRatio;
    final left = (size.width - focusW) / 2;
    final top = (size.height - focusH) / 2;
    final focusRect = Rect.fromLTWH(left, top, focusW, focusH);

    // 1. Area gelap di luar kotak
    final bgPaint = Paint()..color = Colors.black54;
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRect(focusRect),
      ),
      bgPaint,
    );

    // 2. Garis tepi kotak (lebih lembut)
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRect(focusRect, borderPaint);

    // 3. Sudut-sudut tegas
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    const double len = 28.0;

    // Atas-kiri
    canvas.drawLine(Offset(left, top + len), Offset(left, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left + len, top), cornerPaint);

    // Atas-kanan
    canvas.drawLine(
      Offset(left + focusW - len, top),
      Offset(left + focusW, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + focusW, top),
      Offset(left + focusW, top + len),
      cornerPaint,
    );

    // Bawah-kiri
    canvas.drawLine(
      Offset(left, top + focusH - len),
      Offset(left, top + focusH),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + focusH),
      Offset(left + len, top + focusH),
      cornerPaint,
    );

    // Bawah-kanan
    canvas.drawLine(
      Offset(left + focusW - len, top + focusH),
      Offset(left + focusW, top + focusH),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + focusW, top + focusH - len),
      Offset(left + focusW, top + focusH),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
