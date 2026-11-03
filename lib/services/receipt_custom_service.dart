import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import '../models/receipt_custom_model.dart';
import 'local_db_service.dart';

class ReceiptCustomService {
  ReceiptCustomService._();
  static final ReceiptCustomService instance = ReceiptCustomService._();

  static const String _prefKey = 'custom_receipt_settings_json';
  ReceiptCustomModel? _cachedConfig;

  /// Ambil konfigurasi struk custom (tersimpan atau default)
  Future<ReceiptCustomModel> getConfig() async {
    if (_cachedConfig != null) return _cachedConfig!;

    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefKey);

    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        _cachedConfig = ReceiptCustomModel.fromJson(jsonStr);
        return _cachedConfig!;
      } catch (e) {
        debugPrint('Error parsing cached receipt config: $e');
      }
    }

    // Fallback dari database lokal lama jika ada
    try {
      final dbSettings = await LocalDbService.instance.getReceiptSettings();
      _cachedConfig = ReceiptCustomModel(
        storeName: dbSettings['store_name']?.toString() ?? 'NANDA POS',
        storeAddress: dbSettings['store_address']?.toString() ?? 'Pusat Aksesoris & Servis HP',
        storeContact: dbSettings['store_contact']?.toString() ?? 'WhatsApp: 0812-3456-7890',
        footerMessage: dbSettings['footer_message']?.toString() ?? 'Terima Kasih Atas Kunjungan Anda!',
      );
    } catch (_) {
      _cachedConfig = ReceiptCustomModel();
    }

    return _cachedConfig!;
  }

  /// Simpan konfigurasi struk kustom
  Future<bool> saveConfig(ReceiptCustomModel config) async {
    _cachedConfig = config;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, config.toJson());

      // Sync ke DB lokal lama agar modul legacy tetap kompatibel (abaikan jika di unit test/db belum dibuka)
      try {
        await LocalDbService.instance.updateReceiptSettings(
          config.storeName,
          config.storeAddress,
          config.storeContact,
          config.footerMessage,
          58,
        );
      } catch (_) {}
      return true;
    } catch (e) {
      debugPrint('Error saving receipt config: $e');
      return false;
    }
  }

  /// Reset ke pengaturan bawaan
  Future<ReceiptCustomModel> resetToDefault() async {
    final defaultConfig = ReceiptCustomModel();
    await saveConfig(defaultConfig);
    return defaultConfig;
  }

  /// Pilih file logo gambar dari penyimpanan perangkat (Galeri / Dokumen)
  Future<String?> pickLogoImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
      );

      if (result == null || result.files.isEmpty || result.files.single.path == null) {
        return null;
      }

      final sourceFile = File(result.files.single.path!);
      if (!await sourceFile.exists()) return null;

      // Simpan salinan permanen ke dalam direktori aplikasi
      final appDir = await getApplicationDocumentsDirectory();
      final logosDir = Directory(p.join(appDir.path, 'receipt_logos'));
      if (!await logosDir.exists()) {
        await logosDir.create(recursive: true);
      }

      final fileName = 'logo_${DateTime.now().millisecondsSinceEpoch}${p.extension(sourceFile.path)}';
      final targetPath = p.join(logosDir.path, fileName);
      await sourceFile.copy(targetPath);

      return targetPath;
    } catch (e) {
      debugPrint('Error picking receipt logo: $e');
      return null;
    }
  }

  /// Hapus logo gambar kustom
  Future<void> clearLogo(ReceiptCustomModel current) async {
    if (current.logoPath != null) {
      try {
        final file = File(current.logoPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
    current.logoPath = null;
    await saveConfig(current);
  }

  /// Membaca dan mengubah ukuran gambar logo menjadi format raster yang siap dicetak di thermal 58mm (max 384 dot)
  Future<img.Image?> loadAndProcessLogoImage(String? path, int targetWidth) async {
    if (path == null) return null;
    try {
      final file = File(path);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      // Konversi ke grayscale/monokrom dan sesuaikan lebar target
      final clampedWidth = targetWidth.clamp(60, 384);
      final resized = img.copyResize(decoded, width: clampedWidth);
      return img.grayscale(resized);
    } catch (e) {
      debugPrint('Error loading logo image: $e');
      return null;
    }
  }
}
