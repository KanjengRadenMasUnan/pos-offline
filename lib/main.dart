import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/app_theme.dart';
import 'controllers/cashier_controller.dart';
import 'controllers/server_status_controller.dart';
import 'pages/home/home_page.dart';
import 'providers/cart_provider.dart';
import 'services/api_service.dart';

Future<void> main() async {
  await _initializeApp();
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

Future<void> _initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await ApiService().init();
  ApiService().wakeUpServer();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: _buildProviders(),
      child: MaterialApp(
        title: 'Toko Nanda Cell',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomePage(),
      ),
    );
  }

  List<ChangeNotifierProvider> _buildProviders() {
    return [
      ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
      ChangeNotifierProvider<ServerStatusController>(
        create: (_) => ServerStatusController(),
      ),
      ChangeNotifierProvider<CashierController>(
        create: (_) => CashierController(),
      ),
    ];
  }
}
