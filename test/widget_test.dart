import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smartcampus/main.dart';

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    await initializeDateFormatting('id_ID', null);
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MyApp), findsOneWidget);
  });
}
