import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerView extends StatefulWidget {
  final void Function(String) onDetect;

  const ScannerView({super.key, required this.onDetect});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

// Tambahkan Mixin 'SingleTickerProviderStateMixin' untuk animasi
class _ScannerViewState extends State<ScannerView>
    with SingleTickerProviderStateMixin {
  // ====================
  // Properties
  // ====================

  late final MobileScannerController _controller;
  bool _isDetected = false;

  // Properti untuk Animasi Laser
  late AnimationController _animController;
  late Animation<double> _animation;

  // ====================
  // Lifecycle Methods
  // ====================

  @override
  void initState() {
    super.initState();
    _initializeController();
    _initializeAnimation(); // Inisialisasi animasi
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose(); // Hapus controller animasi
    super.dispose();
  }

  // ====================
  // Widget Build Methods
  // ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Latar belakang hitam
      appBar: _buildAppBar(),
      body: _buildScannerView(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Scan Barcode'),
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        _buildMobileScanner(),
        _buildScannerOverlay(),
        _buildInstructionText(),
      ],
    );
  }

  // ====================
  // Component Builders
  // ====================

  Widget _buildMobileScanner() {
    return MobileScanner(
      controller: _controller,
      onDetect: _handleBarcodeDetected,
    );
  }

  Widget _buildScannerOverlay() {
    const double scanArea = 250;

    return Stack(
      children: [
        // 1. Overlay Gelap (Membuat area di luar kotak terlihat gelap)
        ColorFiltered(
          colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcOut),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Center(
                child: Container(
                  height: scanArea,
                  width: scanArea,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. Kotak Border & Laser
        Center(
          child: Container(
            width: scanArea,
            height: scanArea,
            decoration: BoxDecoration(
              // Ubah warna border: Merah (Scan) -> Hijau (Sukses)
              border: Border.all(
                color: _isDetected ? Colors.green : Colors.red,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Tampilkan Laser hanya jika belum terdeteksi
                  if (!_isDetected)
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Positioned(
                          // Laser bergerak dari atas (0) ke bawah (scanArea)
                          top: _animation.value * (scanArea - 5),
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.red,
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionText() {
    return Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          // Ubah teks saat sukses
          child: Text(
            _isDetected ? 'Berhasil Membaca!' : 'Arahkan kamera ke barcode',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ====================
  // Helper Methods
  // ====================

  void _initializeController() {
    _controller = MobileScannerController(
      detectionTimeoutMs: 2000,
      formats: [BarcodeFormat.all],
      autoStart: true,
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  void _initializeAnimation() {
    _animController = AnimationController(
      duration: const Duration(seconds: 2), // Kecepatan laser
      vsync: this,
    )..repeat(reverse: true); // Bergerak bolak-balik (atas-bawah-atas)

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animController);
  }

  void _handleBarcodeDetected(BarcodeCapture capture) {
    if (_isDetected) return;

    final barcodes = capture.barcodes;
    final hasValidBarcode =
        barcodes.isNotEmpty && barcodes.first.rawValue != null;

    if (!hasValidBarcode) return;

    _processBarcodeDetection(barcodes.first.rawValue!);
  }

  void _processBarcodeDetection(String barcodeValue) {
    setState(() {
      _isDetected = true;
      _animController.stop(); // Hentikan laser agar user fokus ke kotak hijau
    });

    // Panggil callback
    widget.onDetect(barcodeValue);

    // Stop kamera
    _controller.stop();

    // Beri jeda 500ms agar user melihat kotak hijau sebelum menutup
    Future.delayed(const Duration(milliseconds: 500), () {
      _navigateBack();
    });
  }

  void _navigateBack() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
