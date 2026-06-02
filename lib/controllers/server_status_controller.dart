import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

enum ServerStatus { checking, online, sleeping }

class ServerStatusController extends ChangeNotifier {
  final ApiService _api = ApiService();

  // --- State Variables ---
  ServerStatus status = ServerStatus.checking;
  Timer? _timer;

  // --- Constructor ---
  ServerStatusController() {
    _initialize();
  }

  // --- Initialization Logic ---
  void _initialize() {
    checkStatus();
    _startPeriodicCheck();
  }

  void _startPeriodicCheck() {
    // Memastikan timer lama dibersihkan sebelum membuat yang baru
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => checkStatus());
  }

  // --- Public Methods ---
  Future<void> checkStatus() async {
    try {
      final isOnline = await _api.checkServerStatus();
      status = isOnline ? ServerStatus.online : ServerStatus.sleeping;
    } catch (e) {
      status = ServerStatus.sleeping;
    } finally {
      notifyListeners();
    }
  }

  // --- Lifecycle Management ---
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
