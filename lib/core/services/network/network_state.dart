import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class NetworkState {
  static final NetworkState instance = NetworkState._();
  final _connectivity = Connectivity();
  final _connectionStatus =
      ValueNotifier<ConnectivityResult>(ConnectivityResult.none);
  StreamSubscription<ConnectivityResult>? _subscription;

  NetworkState._();

  ValueListenable<ConnectivityResult> get status => _connectionStatus;
  bool get isConnected => _connectionStatus.value != ConnectivityResult.none;

  Future<void> initialize() async {
    // 获取初始网络状态
    _connectionStatus.value = await _connectivity.checkConnectivity();

    // 监听网络状态变化
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _connectionStatus.value = result;
    });
  }

  void dispose() {
    _subscription?.cancel();
    _connectionStatus.dispose();
  }
}
