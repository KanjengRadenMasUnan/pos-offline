import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static String get baseUrl =>
      dotenv.env['BASE_URL'] ?? 'https://nandacell.onrender.com/api';
  static const String appName = "Toko Nanda Cell";
  static const String appVersion = "v1.0.0 Stable";
}
