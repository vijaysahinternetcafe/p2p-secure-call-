import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'crypto_manager.dart';

class SignalingClient {
  final String serverUrl;
  final CryptoManager cryptoManager;
  final Function(Map<String, dynamic>) onMessage;
  final VoidCallback? onConnected;
  final VoidCallback? onDisconnected;

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;

  SignalingClient({
    required this.serverUrl,
    required this.cryptoManager,
    required this.onMessage,
    this.onConnected,
    this.onDisconnected,
  });

  Future<void> connect() async {
    if (_isConnected) return;
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final deviceId = cryptoManager.deviceId;
      final signature = await cryptoManager.sign('$deviceId:$timestamp');
      final wsUrl = Uri.parse('$serverUrl?deviceId=$deviceId&timestamp=$timestamp&signature=$signature');

      _channel = IOWebSocketChannel.connect(
        wsUrl,
        pingInterval: const Duration(seconds: 15),
        connectTimeout: const Duration(seconds: 10),
      );

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDisconnected,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      onConnected?.call();
    } catch (e) {
      debugPrint('[Signaling] Connection error: $e');
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      onMessage(data);
    } catch (e) {
      debugPrint('[Signaling] Invalid message: $e');
    }
  }

  void _onError(Object error) {
    _isConnected = false;
    _scheduleReconnect();
  }

  void _onDisconnected() {
    _isConnected = false;
    onDisconnected?.call();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) return;
    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts.clamp(1, 30));
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, connect);
  }

  Future<void> send(Map<String, dynamic> message) async {
    if (!_isConnected || _channel == null) {
      throw Exception('Signaling not connected');
    }
    _channel!.add(jsonEncode(message));
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _isConnected = false;
  }
}
