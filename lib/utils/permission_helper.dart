import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionHelper {
  // ====================
  // Public Methods
  // ====================

  /// Meminta semua izin yang diperlukan agar aplikasi berfungsi optimal.
  /// Menampilkan dialog jika izin ditolak secara permanen.
  static Future<void> requestAppPermissions(BuildContext context) async {
    final permissions = await _getRequiredPermissions();
    final statuses = await permissions.request();

    if (_hasPermanentlyDeniedPermission(statuses) && context.mounted) {
      await _showPermissionSettingsDialog(context);
    }
  }

  // ====================
  // Private Helpers
  // ====================

  /// Menentukan izin apa saja yang diperlukan berdasarkan platform dan versi OS.
  static Future<List<Permission>> _getRequiredPermissions() async {
    final permissions = <Permission>[Permission.camera];

    if (Platform.isAndroid) {
      await _addAndroidPermissions(permissions);
    } else if (Platform.isIOS) {
      await _addIosPermissions(permissions);
    }

    return permissions;
  }

  /// Menambahkan izin spesifik Android berdasarkan versi SDK.
  static Future<void> _addAndroidPermissions(
    List<Permission> permissions,
  ) async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final isAndroid12OrHigher = androidInfo.version.sdkInt >= 31;

    if (isAndroid12OrHigher) {
      // Android 12+ memerlukan izin Bluetooth eksplisit
      permissions.addAll([
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ]);
    } else {
      // Android 11 kebawah memerlukan izin Lokasi untuk scan Bluetooth
      permissions.add(Permission.location);
    }
  }

  /// Menambahkan izin spesifik iOS.
  static Future<void> _addIosPermissions(List<Permission> permissions) async {
    // Tambahkan izin iOS di sini jika diperlukan di masa depan.
  }

  /// Mengecek apakah ada izin yang ditolak secara permanen oleh pengguna.
  static bool _hasPermanentlyDeniedPermission(
    Map<Permission, PermissionStatus> statuses,
  ) {
    return statuses.values.any((status) => status.isPermanentlyDenied);
  }

  // ====================
  // UI Components (Dialogs)
  // ====================

  static Future<void> _showPermissionSettingsDialog(
    BuildContext context,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Izin Diperlukan'),
        content: const Text(
          'Aplikasi membutuhkan izin Kamera dan Bluetooth agar bisa berjalan normal.\n\n'
          'Mohon buka Pengaturan dan aktifkan izin secara manual.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }
}
