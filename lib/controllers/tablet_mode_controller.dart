import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TabletModeController extends ChangeNotifier {
  static const String _prefKey = 'tablet_mode_landscape';

  bool _isTabletLandscape = false;
  bool _isInitialized = false;

  bool get isTabletLandscape => _isTabletLandscape;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isTabletLandscape = prefs.getBool(_prefKey) ?? false;
      _applyOrientation();
    } catch (e) {
      debugPrint('Error loading tablet mode preference: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> setTabletLandscape(bool enabled) async {
    if (_isTabletLandscape == enabled) return;
    _isTabletLandscape = enabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, enabled);
    } catch (e) {
      debugPrint('Error saving tablet mode preference: $e');
    }

    await _applyOrientation();
  }

  Future<void> toggleTabletLandscape() async {
    await setTabletLandscape(!_isTabletLandscape);
  }

  Future<void> _applyOrientation() async {
    if (_isTabletLandscape) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  /// Helper untuk mengecek apakah tampilan harus menggunakan layout tablet horizontal
  bool isTabletLayout(BuildContext context) {
    if (_isTabletLandscape) return true;
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    return orientation == Orientation.landscape && size.width >= 680;
  }
}

