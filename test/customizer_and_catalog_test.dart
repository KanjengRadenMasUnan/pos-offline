import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcampus/controllers/server_status_controller.dart';
import 'package:smartcampus/controllers/tablet_mode_controller.dart';
import 'package:smartcampus/pages/home/home_page.dart';
import 'package:smartcampus/pages/settings/receipt_customizer_page.dart';
import 'package:smartcampus/pages/product/product_list_page.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
  });

  group('UI Modernization & Bug Fix Tests', () {
    testWidgets('HomePage has no quick action capsules and drawer only has Pengaturan Sistem',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ServerStatusController()),
            ChangeNotifierProvider(create: (_) => TabletModeController()),
          ],
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure quick action capsules are gone
      expect(find.text("Struk 58mm"), findsNothing);
      expect(find.text("Cari Barang"), findsNothing);

      // Open drawer
      final scaffoldState = tester.firstState<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Drawer contains strictly "Pengaturan Sistem"
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text("Pengaturan Sistem")),
        findsOneWidget,
      );

      // Drawer should NOT contain the removed items
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text("Kasir Transaksi")),
        findsNothing,
      );
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text("Katalog Produk")),
        findsNothing,
      );
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text("Laporan & Analitik")),
        findsNothing,
      );
      expect(
        find.descendant(of: find.byType(Drawer), matching: find.text("Kustomisasi Struk 58mm")),
        findsNothing,
      );
    });

    testWidgets('ReceiptCustomizerPage renders without overflow on 360x640 mobile screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;

      // Seed mock SharedPreferences
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => TabletModeController()),
          ],
          child: const MaterialApp(
            home: ReceiptCustomizerPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Kustomisasi Struk 58mm"), findsOneWidget);
      expect(find.text("PREVIEW KERTAS 58MM • 32 KOLOM"), findsOneWidget);
      expect(find.text("Simpan Desain Struk"), findsOneWidget);
      expect(find.text("Uji Cetak 58mm"), findsOneWidget);

      // Scroll until alignment section is visible
      await tester.scrollUntilVisible(
        find.text("Perataan Posisi Horizontal:"),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text("Perataan Posisi Horizontal:"), findsOneWidget);
      expect(find.text("Tengah"), findsOneWidget);
      expect(find.text("Lebar Penuh (360 px)"), findsOneWidget);
    });

    testWidgets('ProductListPage modern layout renders with summary metrics strip and search',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;

      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => TabletModeController()),
          ],
          child: const MaterialApp(
            home: ProductListPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Katalog Produk"), findsOneWidget);
      expect(find.text("Total Item"), findsOneWidget);
      expect(find.text("Nilai Aset Stok"), findsOneWidget);
      expect(find.text("Item Menipis"), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text("Tambah Barang"), findsOneWidget);
    });
  });
}
