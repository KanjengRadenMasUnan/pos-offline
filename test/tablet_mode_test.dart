import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcampus/controllers/tablet_mode_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TabletModeController Tests', () {
    test('Default tablet mode state is false and loads correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = TabletModeController();
      expect(controller.isTabletLandscape, isFalse);

      await controller.init();
      expect(controller.isTabletLandscape, isFalse);
    });

    test('Loads persisted true value from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'tablet_mode_landscape': true});
      final controller = TabletModeController();
      await controller.init();
      expect(controller.isTabletLandscape, isTrue);
    });

    test('toggleTabletLandscape flips state and saves preference', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = TabletModeController();
      await controller.init();
      expect(controller.isTabletLandscape, isFalse);

      await controller.setTabletLandscape(true);
      expect(controller.isTabletLandscape, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('tablet_mode_landscape'), isTrue);

      await controller.toggleTabletLandscape();
      expect(controller.isTabletLandscape, isFalse);
      expect(prefs.getBool('tablet_mode_landscape'), isFalse);
    });
  });
}
