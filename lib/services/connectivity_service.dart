import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'offline_queue_service.dart';

class ConnectivityService extends ChangeNotifier {
  ConnectivityService._internal() {
    _init();
  }

  static final ConnectivityService instance = ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _isOnlineController = StreamController<bool>.broadcast();

  bool _isOnline = true;
  bool get isOnline => _isOnline;
  Stream<bool> get isOnlineStream => _isOnlineController.stream;

  Timer? _debounce;

  Future<void> _init() async {
    // Initial check
    final results = await _connectivity.checkConnectivity();
    _setStatus(_hasAnyNetwork(results));
    if (_isOnline) {
      await OfflineQueueService.instance.processQueue();
    }

    // Listen connectivity changes with debounce to avoid brief blips
    _connectivity.onConnectivityChanged.listen((results) async {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () async {
        final online = _hasAnyNetwork(results);
        _setStatus(online);
        if (online) {
          await OfflineQueueService.instance.processQueue();
        }
      });
    });
  }

  bool _hasAnyNetwork(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }

  void _setStatus(bool online) {
    if (_isOnline == online) return; // emit only on real change
    _isOnline = online;
    _isOnlineController.add(_isOnline);
    notifyListeners();
  }

  Future<bool> isOnlineAsync() async => _isOnline;

  @override
  void dispose() {
    _debounce?.cancel();
    _isOnlineController.close();
    super.dispose();
  }
}
