import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcampus/models/receipt_custom_model.dart';
import 'package:smartcampus/services/receipt_custom_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReceiptCustomModel & Customizer Tests', () {
    test('Default model values match 58mm thermal specifications', () {
      final model = ReceiptCustomModel();

      expect(model.showLogo, isTrue);
      expect(model.logoPosition, equals(ReceiptLogoPosition.top));
      expect(model.logoAlignment, equals(ReceiptLogoAlign.center));
      expect(model.logoSize, equals(ReceiptLogoSize.medium));
      expect(model.storeName, equals('NANDA POS'));
      expect(model.dividerStyle, equals(ReceiptDividerStyle.dash));
      expect(model.dividerStyle.pattern.length, equals(32)); // Standard 58mm 32 columns
      expect(model.showInvoiceQr, isTrue);
    });

    test('Serialization to/from Map and JSON preserves all positions and logo fields', () {
      final original = ReceiptCustomModel(
        showLogo: true,
        logoPath: '/tmp/test_logo.png',
        logoPosition: ReceiptLogoPosition.afterTotal,
        logoAlignment: ReceiptLogoAlign.right,
        logoSize: ReceiptLogoSize.full,
        storeName: 'TOKO KASIR KITA',
        storeNameSize: 'extra_large',
        showHeaderNote: true,
        headerNote: 'Murah Berkualitas',
        dividerStyle: ReceiptDividerStyle.star,
        showTax: true,
        taxPercent: 12.0,
        showInvoiceQr: true,
      );

      final jsonStr = original.toJson();
      final restored = ReceiptCustomModel.fromJson(jsonStr);

      expect(restored.showLogo, isTrue);
      expect(restored.logoPath, equals('/tmp/test_logo.png'));
      expect(restored.logoPosition, equals(ReceiptLogoPosition.afterTotal));
      expect(restored.logoAlignment, equals(ReceiptLogoAlign.right));
      expect(restored.logoSize, equals(ReceiptLogoSize.full));
      expect(restored.storeName, equals('TOKO KASIR KITA'));
      expect(restored.storeNameSize, equals('extra_large'));
      expect(restored.dividerStyle, equals(ReceiptDividerStyle.star));
      expect(restored.dividerStyle.pattern, equals('********************************'));
      expect(restored.showTax, isTrue);
      expect(restored.taxPercent, equals(12.0));
      expect(restored.showInvoiceQr, isTrue);
    });

    test('ReceiptLogoPosition can be set to any of the 5 positions', () {
      expect(ReceiptLogoPosition.fromCode('top'), equals(ReceiptLogoPosition.top));
      expect(ReceiptLogoPosition.fromCode('after_header'), equals(ReceiptLogoPosition.afterHeader));
      expect(ReceiptLogoPosition.fromCode('before_items'), equals(ReceiptLogoPosition.beforeItems));
      expect(ReceiptLogoPosition.fromCode('after_total'), equals(ReceiptLogoPosition.afterTotal));
      expect(ReceiptLogoPosition.fromCode('bottom'), equals(ReceiptLogoPosition.bottom));
      expect(ReceiptLogoPosition.fromCode('unknown'), equals(ReceiptLogoPosition.top)); // fallback
    });

    test('ReceiptCustomService saves and retrieves config via SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final service = ReceiptCustomService.instance;

      final config = await service.getConfig();
      expect(config.storeName, isNotEmpty);

      config.storeName = 'WARUNG MODERN 58MM';
      config.logoPosition = ReceiptLogoPosition.bottom;
      await service.saveConfig(config);

      final updated = await service.getConfig();
      expect(updated.storeName, equals('WARUNG MODERN 58MM'));
      expect(updated.logoPosition, equals(ReceiptLogoPosition.bottom));
    });
  });
}

