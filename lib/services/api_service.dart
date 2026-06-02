import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import '../models/transaction_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;

  String get currentBaseUrl {
    try {
      return _dio.options.baseUrl;
    } catch (_) {
      return Config.baseUrl;
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('custom_base_url') ?? Config.baseUrl;

    _dio = Dio(
      BaseOptions(
        baseUrl: savedUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          "X-Requested-With": "XMLHttpRequest",
        },
      ),
    );
  }

  Future<void> updateBaseUrl(String newUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final formattedUrl = newUrl.trim();

    await prefs.setString('custom_base_url', formattedUrl);
    _dio.options.baseUrl = formattedUrl;

    print('ApiService: URL berhasil diubah ke $formattedUrl');
  }

  Future<bool> checkServerStatus() async {
    try {
      final response = await _dio
          .get('/ping')
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> wakeUpServer() async {
    try {
      await _dio.get(
        '/ping',
        options: Options(receiveTimeout: const Duration(seconds: 15)),
      );
    } catch (_) {}
  }

  Future<Product?> addProduct(
    String name,
    int price,
    int stock,
    String category, {
    String? code,
  }) async {
    try {
      final data = {
        'name': name,
        'price': price,
        'stock': stock,
        'category': category,
      };

      if (code != null && code.isNotEmpty) {
        data['code'] = code;
      }

      final response = await _dio.post('/products', data: data);
      final body = response.data;

      if (body is Map && body['data'] != null) {
        return Product.fromJson(Map<String, dynamic>.from(body['data']));
      }

      return Product.fromJson(Map<String, dynamic>.from(body));
    } catch (e) {
      throw Exception(_handleError(e as DioException));
    }
  }

  Future<List<Product>> getAllProducts() async {
    try {
      final response = await _dio.get('/products');
      return _parseProductList(response.data);
    } catch (e) {
      throw Exception(_handleError(e as DioException));
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await _dio.get(
        '/products/search',
        queryParameters: {'query': query},
      );
      return _parseProductList(response.data);
    } catch (e) {
      return [];
    }
  }

  Future<Product?> getProductByCode(String code) async {
    try {
      final response = await _dio.get('/products/$code');
      final body = response.data;
      final productData = (body is Map && body['data'] != null)
          ? body['data']
          : body;

      return Product.fromJson(Map<String, dynamic>.from(productData));
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateProduct(
    int id,
    String name,
    int price,
    int stock,
    String category,
  ) async {
    try {
      await _dio.put(
        '/products/$id',
        data: {
          'name': name,
          'price': price,
          'stock': stock,
          'category': category,
        },
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      final response = await _dio.delete('/products/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('API Error: $e');
      return false;
    }
  }

  // Transaction Operations
  Future<String?> checkout(List<CartItem> items, int total) async {
    try {
      final itemsJson = items.map((item) {
        return {
          'product_id': item.product.id,
          'qty': item.qty,
          'price': item.product.price,
        };
      }).toList();

      final response = await _dio.post(
        '/checkout',
        data: {'total_amount': total, 'items': itemsJson},
      );

      return response.data['invoice_number'];
    } catch (e) {
      return null;
    }
  }

  Future<List<TransactionModel>> getTransactionHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = <String, dynamic>{};

      if (startDate != null && endDate != null) {
        params['start_date'] = startDate.toIso8601String().split('T')[0];
        params['end_date'] = endDate.toIso8601String().split('T')[0];
      }

      final response = await _dio.get('/transactions', queryParameters: params);

      List listData = [];

      if (response.data is List) {
        listData = response.data;
      } else if (response.data is Map && response.data['data'] is List) {
        listData = response.data['data'];
      }

      return listData.map((e) => TransactionModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // Helper Methods
  String _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Server tidak merespon (timeout)';

      case DioExceptionType.connectionError:
        return 'Tidak ada koneksi internet';

      case DioExceptionType.badResponse:
        return e.response?.data?['message'] ??
            'Server error (${e.response?.statusCode})';

      default:
        return 'Terjadi kesalahan jaringan';
    }
  }

  List<Product> _parseProductList(dynamic responseData) {
    List<dynamic> listData = [];

    if (responseData is List) {
      listData = responseData;
    } else if (responseData is Map && responseData['data'] != null) {
      listData = responseData['data'];
    }

    return listData.map((json) => Product.fromJson(json)).toList();
  }
}
