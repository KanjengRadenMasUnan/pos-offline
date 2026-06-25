import 'package:shared_preferences/shared_preferences.dart';

class CategoryService {
  static const _key = 'categories_list';

  static const List<String> defaultCategories = [
    'Umum',
    'Kabel Data',
    'Powerbank',
    'Memory',
    'Charger',
    'Batok',
    'Headset',
    'Casing',
    'Kartu Perdana',
    'Tempered Glass',
    'Voucher',
    'Service',
  ];

  /// Ambil semua kategori (jika belum ada, simpan default)
  static Future<List<String>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_key);
    if (stored == null || stored.isEmpty) {
      await prefs.setStringList(_key, defaultCategories);
      return List.from(defaultCategories);
    }
    return List.from(stored);
  }

  /// Tambah kategori baru (cek duplikasi & normalisasi)
  static Future<bool> addCategory(String category) async {
    final normalized = category.trim();
    if (normalized.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final categories = await getCategories();
    if (categories.any((c) => c.toLowerCase() == normalized.toLowerCase())) {
      return false; // sudah ada (case-insensitive)
    }
    categories.add(normalized);
    await prefs.setStringList(_key, categories);
    return true;
  }

  /// Hapus kategori (opsional)
  static Future<void> removeCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final categories = await getCategories();
    categories.removeWhere((c) => c.toLowerCase() == category.toLowerCase());
    await prefs.setStringList(_key, categories);
  }

  /// Reset ke default
  static Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, defaultCategories);
  }
}
